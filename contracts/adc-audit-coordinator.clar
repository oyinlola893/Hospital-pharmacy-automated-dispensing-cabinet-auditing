;; ADC Audit Coordinator
;; Smart contract for hospital pharmacy automated dispensing cabinet auditing
;; Tracks cabinet transactions, reconciles inventory, identifies discrepancies, and prevents medication diversion

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-not-found (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-cabinet-inactive (err u105))
(define-constant err-insufficient-inventory (err u106))
(define-constant err-discrepancy-exists (err u107))

;; Access level constants
(define-constant access-none u0)
(define-constant access-technician u1)
(define-constant access-pharmacist u2)
(define-constant access-auditor u3)
(define-constant access-admin u4)

;; Transaction type constants
(define-constant tx-type-removal u1)
(define-constant tx-type-restock u2)
(define-constant tx-type-adjustment u3)
(define-constant tx-type-waste u4)

;; Discrepancy status constants
(define-constant status-open u1)
(define-constant status-investigating u2)
(define-constant status-resolved u3)
(define-constant status-escalated u4)

;; Data Variables
(define-data-var cabinet-nonce uint u0)
(define-data-var transaction-nonce uint u0)
(define-data-var discrepancy-nonce uint u0)

;; Data Maps

;; Cabinet registry
(define-map cabinets
    { cabinet-id: uint }
    {
        location: (string-ascii 100),
        capacity: uint,
        controlled-substance: bool,
        active: bool,
        registered-by: principal,
        registered-at: uint
    }
)

;; Cabinet inventory tracking
(define-map cabinet-inventory
    { cabinet-id: uint, medication-id: (string-ascii 50) }
    {
        expected-quantity: uint,
        actual-quantity: uint,
        last-reconciled: uint,
        last-reconciled-by: principal
    }
)

;; Transaction ledger
(define-map transactions
    { transaction-id: uint }
    {
        cabinet-id: uint,
        medication-id: (string-ascii 50),
        transaction-type: uint,
        quantity: uint,
        performed-by: principal,
        timestamp: uint,
        notes: (string-ascii 200)
    }
)

;; Discrepancy tracking
(define-map discrepancies
    { discrepancy-id: uint }
    {
        cabinet-id: uint,
        medication-id: (string-ascii 50),
        expected-quantity: uint,
        actual-quantity: uint,
        variance: int,
        status: uint,
        flagged-by: principal,
        flagged-at: uint,
        resolved-by: (optional principal),
        resolved-at: (optional uint),
        investigation-notes: (string-ascii 500)
    }
)

;; Access control
(define-map user-access
    { user: principal }
    { access-level: uint }
)

;; Cabinet transaction history index
(define-map cabinet-transaction-count
    { cabinet-id: uint }
    { count: uint }
)

;; User transaction history index
(define-map user-transaction-count
    { user: principal }
    { count: uint }
)

;; Private Functions

(define-private (is-authorized (required-level uint))
    (let ((user-level (default-to access-none (get access-level (map-get? user-access { user: tx-sender })))))
        (>= user-level required-level)
    )
)

(define-private (calculate-variance (expected uint) (actual uint))
    (if (>= actual expected)
        (to-int (- actual expected))
        (* -1 (to-int (- expected actual)))
    )
)

(define-private (increment-cabinet-tx-count (cabinet-id uint))
    (let ((current-count (default-to u0 (get count (map-get? cabinet-transaction-count { cabinet-id: cabinet-id })))))
        (map-set cabinet-transaction-count
            { cabinet-id: cabinet-id }
            { count: (+ current-count u1) }
        )
    )
)

(define-private (increment-user-tx-count (user principal))
    (let ((current-count (default-to u0 (get count (map-get? user-transaction-count { user: user })))))
        (map-set user-transaction-count
            { user: user }
            { count: (+ current-count u1) }
        )
    )
)

;; Public Functions

;; Initialize contract owner with admin access
(define-public (initialize)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set user-access
            { user: contract-owner }
            { access-level: access-admin }
        ))
    )
)

;; Grant access to user
(define-public (grant-access (user principal) (level uint))
    (begin
        (asserts! (is-authorized access-admin) err-unauthorized)
        (asserts! (<= level access-admin) err-invalid-input)
        (ok (map-set user-access
            { user: user }
            { access-level: level }
        ))
    )
)

;; Revoke access from user
(define-public (revoke-access (user principal))
    (begin
        (asserts! (is-authorized access-admin) err-unauthorized)
        (ok (map-set user-access
            { user: user }
            { access-level: access-none }
        ))
    )
)

;; Register new ADC cabinet
(define-public (register-cabinet (location (string-ascii 100)) (capacity uint) (controlled-substance bool))
    (let ((new-cabinet-id (+ (var-get cabinet-nonce) u1)))
        (asserts! (is-authorized access-pharmacist) err-unauthorized)
        (asserts! (> capacity u0) err-invalid-input)
        (var-set cabinet-nonce new-cabinet-id)
        (ok (map-set cabinets
            { cabinet-id: new-cabinet-id }
            {
                location: location,
                capacity: capacity,
                controlled-substance: controlled-substance,
                active: true,
                registered-by: tx-sender,
                registered-at: block-height
            }
        ))
    )
)

;; Deactivate cabinet
(define-public (deactivate-cabinet (cabinet-id uint))
    (let ((cabinet-data (unwrap! (map-get? cabinets { cabinet-id: cabinet-id }) err-not-found)))
        (asserts! (is-authorized access-pharmacist) err-unauthorized)
        (ok (map-set cabinets
            { cabinet-id: cabinet-id }
            (merge cabinet-data { active: false })
        ))
    )
)

;; Record medication transaction
(define-public (record-transaction 
    (cabinet-id uint) 
    (medication-id (string-ascii 50)) 
    (tx-type uint) 
    (quantity uint)
    (notes (string-ascii 200)))
    (let (
        (new-tx-id (+ (var-get transaction-nonce) u1))
        (cabinet-data (unwrap! (map-get? cabinets { cabinet-id: cabinet-id }) err-not-found))
        (inventory-data (default-to 
            { expected-quantity: u0, actual-quantity: u0, last-reconciled: u0, last-reconciled-by: contract-owner }
            (map-get? cabinet-inventory { cabinet-id: cabinet-id, medication-id: medication-id })
        ))
    )
        (asserts! (is-authorized access-technician) err-unauthorized)
        (asserts! (get active cabinet-data) err-cabinet-inactive)
        (asserts! (> quantity u0) err-invalid-input)
        (asserts! (or (is-eq tx-type tx-type-removal) (is-eq tx-type tx-type-restock) (is-eq tx-type tx-type-adjustment) (is-eq tx-type tx-type-waste)) err-invalid-input)
        
        ;; Update expected quantity based on transaction type
        (let ((new-expected-qty 
            (if (is-eq tx-type tx-type-removal)
                (if (>= (get expected-quantity inventory-data) quantity)
                    (- (get expected-quantity inventory-data) quantity)
                    u0
                )
                (if (is-eq tx-type tx-type-restock)
                    (+ (get expected-quantity inventory-data) quantity)
                    (get expected-quantity inventory-data)
                )
            )
        ))
        
            (var-set transaction-nonce new-tx-id)
            (map-set transactions
                { transaction-id: new-tx-id }
                {
                    cabinet-id: cabinet-id,
                    medication-id: medication-id,
                    transaction-type: tx-type,
                    quantity: quantity,
                    performed-by: tx-sender,
                    timestamp: block-height,
                    notes: notes
                }
            )
            (map-set cabinet-inventory
                { cabinet-id: cabinet-id, medication-id: medication-id }
                (merge inventory-data { expected-quantity: new-expected-qty })
            )
            (increment-cabinet-tx-count cabinet-id)
            (increment-user-tx-count tx-sender)
            (ok new-tx-id)
        )
    )
)

;; Reconcile inventory with physical count
(define-public (reconcile-inventory (cabinet-id uint) (medication-id (string-ascii 50)) (actual-count uint))
    (let (
        (cabinet-data (unwrap! (map-get? cabinets { cabinet-id: cabinet-id }) err-not-found))
        (inventory-data (default-to 
            { expected-quantity: u0, actual-quantity: u0, last-reconciled: u0, last-reconciled-by: contract-owner }
            (map-get? cabinet-inventory { cabinet-id: cabinet-id, medication-id: medication-id })
        ))
    )
        (asserts! (is-authorized access-technician) err-unauthorized)
        (asserts! (get active cabinet-data) err-cabinet-inactive)
        
        (ok (map-set cabinet-inventory
            { cabinet-id: cabinet-id, medication-id: medication-id }
            {
                expected-quantity: (get expected-quantity inventory-data),
                actual-quantity: actual-count,
                last-reconciled: block-height,
                last-reconciled-by: tx-sender
            }
        ))
    )
)

;; Flag discrepancy
(define-public (flag-discrepancy (cabinet-id uint) (medication-id (string-ascii 50)))
    (let (
        (new-discrepancy-id (+ (var-get discrepancy-nonce) u1))
        (inventory-data (unwrap! (map-get? cabinet-inventory { cabinet-id: cabinet-id, medication-id: medication-id }) err-not-found))
        (variance (calculate-variance (get expected-quantity inventory-data) (get actual-quantity inventory-data)))
    )
        (asserts! (is-authorized access-technician) err-unauthorized)
        (asserts! (not (is-eq variance 0)) err-invalid-input)
        
        (var-set discrepancy-nonce new-discrepancy-id)
        (ok (map-set discrepancies
            { discrepancy-id: new-discrepancy-id }
            {
                cabinet-id: cabinet-id,
                medication-id: medication-id,
                expected-quantity: (get expected-quantity inventory-data),
                actual-quantity: (get actual-quantity inventory-data),
                variance: variance,
                status: status-open,
                flagged-by: tx-sender,
                flagged-at: block-height,
                resolved-by: none,
                resolved-at: none,
                investigation-notes: ""
            }
        ))
    )
)

;; Update discrepancy investigation
(define-public (update-investigation (discrepancy-id uint) (new-status uint) (notes (string-ascii 500)))
    (let ((discrepancy-data (unwrap! (map-get? discrepancies { discrepancy-id: discrepancy-id }) err-not-found)))
        (asserts! (is-authorized access-pharmacist) err-unauthorized)
        (asserts! (or (is-eq new-status status-open) (is-eq new-status status-investigating) (is-eq new-status status-resolved) (is-eq new-status status-escalated)) err-invalid-input)
        
        (ok (map-set discrepancies
            { discrepancy-id: discrepancy-id }
            (merge discrepancy-data {
                status: new-status,
                investigation-notes: notes,
                resolved-by: (if (is-eq new-status status-resolved) (some tx-sender) (get resolved-by discrepancy-data)),
                resolved-at: (if (is-eq new-status status-resolved) (some block-height) (get resolved-at discrepancy-data))
            })
        ))
    )
)

;; Read-Only Functions

;; Get cabinet information
(define-read-only (get-cabinet-info (cabinet-id uint))
    (ok (map-get? cabinets { cabinet-id: cabinet-id }))
)

;; Get inventory status
(define-read-only (get-inventory-status (cabinet-id uint) (medication-id (string-ascii 50)))
    (ok (map-get? cabinet-inventory { cabinet-id: cabinet-id, medication-id: medication-id }))
)

;; Get transaction details
(define-read-only (get-transaction (transaction-id uint))
    (ok (map-get? transactions { transaction-id: transaction-id }))
)

;; Get discrepancy details
(define-read-only (get-discrepancy (discrepancy-id uint))
    (ok (map-get? discrepancies { discrepancy-id: discrepancy-id }))
)

;; Get user access level
(define-read-only (get-access-level (user principal))
    (ok (default-to access-none (get access-level (map-get? user-access { user: user }))))
)

;; Get cabinet transaction count
(define-read-only (get-cabinet-tx-count (cabinet-id uint))
    (ok (default-to u0 (get count (map-get? cabinet-transaction-count { cabinet-id: cabinet-id }))))
)

;; Get user transaction count
(define-read-only (get-user-tx-count (user principal))
    (ok (default-to u0 (get count (map-get? user-transaction-count { user: user }))))
)

;; Get current nonces
(define-read-only (get-cabinet-nonce)
    (ok (var-get cabinet-nonce))
)

(define-read-only (get-transaction-nonce)
    (ok (var-get transaction-nonce))
)

(define-read-only (get-discrepancy-nonce)
    (ok (var-get discrepancy-nonce))
)

;; Check if cabinet is active
(define-read-only (is-cabinet-active (cabinet-id uint))
    (ok (default-to false (get active (map-get? cabinets { cabinet-id: cabinet-id }))))
)

;; Check if user has minimum access level
(define-read-only (has-access (user principal) (required-level uint))
    (let ((user-level (default-to access-none (get access-level (map-get? user-access { user: user })))))
        (ok (>= user-level required-level))
    )
)

