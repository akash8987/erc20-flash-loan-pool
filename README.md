# ERC20 Flash Loan Pool

An expert-level, minimal liquidity pool designed to execute lightning-fast flash loans using any standard ERC20 token. The system allows smart contracts to borrow the pool's entire liquidity balance without collateral, provided the capital is returned within the exact same transaction block.

## Features
- **Collateral-Free Borrowing:** Instant utility access to pool liquidity.
- **Custom Flash Fee:** Configurable fee parameters (set to zero by default for maximum capital utility).
- **Reentrancy Protection:** Safe execution loops preventing malicious drain vectors.

## Installation

1. Install required packages:
   ```bash
   npm install
