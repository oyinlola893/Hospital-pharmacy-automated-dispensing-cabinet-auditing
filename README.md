# Hospital Pharmacy Automated Dispensing Cabinet Auditing

A blockchain-based medication management platform built on Stacks that reconciles automated dispensing cabinet (ADC) inventory, identifies discrepancies, investigates variances, and prevents medication diversion in hospital pharmacy settings.

## Overview

Automated Dispensing Cabinets (ADCs) are critical infrastructure in hospital pharmacies, containing controlled substances and high-value medications. This smart contract system provides an immutable audit trail for cabinet transactions, enabling:

- Real-time inventory reconciliation
- Discrepancy detection and flagging
- Variance investigation workflows
- Medication diversion prevention
- Regulatory compliance documentation

## Problem Statement

Hospital pharmacies face significant challenges with ADC management:

1. **Medication Diversion**: Unauthorized removal of controlled substances
2. **Inventory Discrepancies**: Mismatches between physical counts and system records
3. **Audit Trail Gaps**: Incomplete or tampered transaction logs
4. **Regulatory Compliance**: DEA and Joint Commission requirements
5. **Manual Reconciliation**: Time-consuming and error-prone processes

## Solution

This smart contract platform provides:

- **Immutable Transaction Logs**: Every ADC access recorded on-chain
- **Automated Discrepancy Detection**: Real-time variance identification
- **Investigation Workflows**: Structured processes for resolving issues
- **Access Control**: Role-based permissions for pharmacy staff
- **Compliance Reports**: Audit-ready documentation

## Features

### Core Functionality

- **Cabinet Registration**: Initialize ADC units with location and capacity
- **Transaction Recording**: Log all medication removals and restocks
- **Inventory Reconciliation**: Compare expected vs. actual counts
- **Discrepancy Flagging**: Automatic variance detection
- **Investigation Management**: Track resolution of identified issues
- **Access Audit Trail**: Complete history of all cabinet interactions

### Security Features

- Role-based access control (pharmacist, technician, auditor)
- Medication diversion alerts
- Tamper-evident transaction logs
- Multi-signature requirements for controlled substances

### Compliance Support

- DEA audit trail requirements
- Joint Commission standards
- State pharmacy board regulations
- Hospital policy enforcement

## Architecture

### Smart Contract Components

- **ADC Registry**: Cabinet registration and metadata
- **Transaction Ledger**: Comprehensive medication movement logs
- **Inventory Manager**: Real-time stock tracking
- **Discrepancy Tracker**: Variance identification and resolution
- **Access Control**: Permission management system

### Data Structures

- **Cabinet Records**: Location, capacity, controlled substance status
- **Transaction Logs**: User, medication, quantity, timestamp
- **Inventory Snapshots**: Expected vs. actual counts
- **Discrepancy Reports**: Variance details and investigation status

## Use Cases

### 1. Daily Reconciliation
Pharmacy technicians perform routine counts, recording results on-chain for automatic variance detection.

### 2. Controlled Substance Auditing
Pharmacists investigate discrepancies in Schedule II medications, documenting findings immutably.

### 3. Diversion Investigation
Security teams access complete audit trails when suspected theft occurs.

### 4. Regulatory Inspections
Auditors retrieve comprehensive transaction histories for compliance reviews.

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity
- **Token Standard**: None (audit trail only)
- **Access Control**: Principal-based permissions

## Contract Functions

### Public Functions
- `register-cabinet`: Initialize new ADC unit
- `record-transaction`: Log medication removal/restock
- `reconcile-inventory`: Submit physical count
- `flag-discrepancy`: Report variance
- `update-investigation`: Record resolution steps
- `grant-access`: Assign permissions

### Read-Only Functions
- `get-cabinet-info`: Retrieve ADC metadata
- `get-transaction-history`: Query movement logs
- `get-discrepancies`: List open variances
- `get-access-level`: Check user permissions

## Installation

```bash
# Clone repository
git clone https://github.com/oyinlola893/Hospital-pharmacy-automated-dispensing-cabinet-auditing.git

# Navigate to project
cd Hospital-pharmacy-automated-dispensing-cabinet-auditing

# Install dependencies
npm install

# Run tests
npm test
```

## Development

### Prerequisites
- Clarinet CLI
- Node.js 16+
- Stacks wallet

### Local Testing

```bash
# Check contract syntax
clarinet check

# Run test suite
clarinet test

# Start local devnet
clarinet integrate
```

## Deployment

### Testnet
```bash
clarinet deployment generate --testnet
clarinet deployment apply --testnet
```

### Mainnet
```bash
clarinet deployment generate --mainnet
clarinet deployment apply --mainnet
```

## Security Considerations

- **Data Privacy**: PHI/PII should not be stored on-chain
- **Access Control**: Strict role-based permissions required
- **Audit Integrity**: Immutable logs prevent tampering
- **Key Management**: Secure principal/wallet handling essential

## Regulatory Compliance

This system supports compliance with:

- **DEA**: Controlled substance tracking (21 CFR 1301-1308)
- **Joint Commission**: Medication management standards
- **State Boards**: Pharmacy practice regulations
- **HIPAA**: Privacy rule compliance (when properly implemented)

## Roadmap

- [ ] Enhanced reporting dashboards
- [ ] Integration with hospital EMR systems
- [ ] Machine learning diversion detection
- [ ] Multi-facility deployment tools
- [ ] Mobile app for field auditing

## Contributing

Contributions welcome! Please review our contributing guidelines and submit pull requests for review.

## License

MIT License - see LICENSE file for details

## Support

For questions or issues:
- GitHub Issues: [Project Issues](https://github.com/oyinlola893/Hospital-pharmacy-automated-dispensing-cabinet-auditing/issues)
- Email: support@example.com

## Disclaimer

This software is provided for informational purposes. Users are responsible for ensuring compliance with all applicable laws, regulations, and organizational policies. Not intended as legal or regulatory advice.

---

**Built with Clarity on Stacks** | **Securing Hospital Pharmacy Operations**
