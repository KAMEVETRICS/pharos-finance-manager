---
name: pharos-finance-manager
description: >
  Pharos Finance Manager Skill for managing funds on Pharos Network. Handles deposits/locks, token swaps, batch payments, and portfolio snapshots — all through a single deployed FinanceManager contract.
  Invoke whenever the user wants to deploy a finance manager, deposit/lock funds, withdraw funds, swap tokens, execute a batch pay, or check their portfolio snapshot on the Pharos network. Supports dynamic tokens (USDC, USDT, WETH, etc.).
version: 0.1.0
requires:
  anyBins:
  - cast
  - forge
---

# Pharos Finance Manager Skill

Developer toolkit for the Pharos blockchain. Perform on-chain queries, send transactions, deploy and verify contracts via Foundry (`cast` / `forge`) CLI commands.

## Prerequisites

1. **Install Foundry** (MANDATORY — MUST be done before ANY other action):
   - The Agent MUST first run `which cast` to check if Foundry is installed.
   - If `cast` is NOT found, the Agent MUST immediately run the following installation commands. **Do NOT skip installation. Do NOT fall back to curl/JSON-RPC as a workaround. Do NOT proceed with any other task until Foundry is installed.**
     ```bash
     curl -L https://foundry.paradigm.xyz | bash
     source ~/.zshenv && foundryup
     cast --version
     ```
   - If installation fails, inform the user and STOP.
2. **Configure Private Key**: Write operations require a private key, provided via `$PRIVATE_KEY`.
3. **Configure Finance Manager**: The Finance Manager contract address must be set. Example: `export FINANCE_MANAGER=0xb1085d955a8DBEe3f6D01d76ee9B0C2258327080`

## Network Configuration & Token Resolution

- **Testnet RPC URL**: `https://atlantic.dplabs-internal.com`
- **Mainnet RPC URL**: `https://rpc.pharos.xyz`

**Dynamic Token Support**: The user can provide any asset of choice by name (e.g. "USDC", "WETH") or by contract address.
If the user specifies a token by name without providing an address, you should use the following known standard addresses (or ask the user if the token is not on this list):
- **Mock USDC (Testnet)**: `0xb7a09F05d363E038e80ef8c49543255F6920a190`
- *(Add other token addresses here as deployed on Pharos)*

If the user provides a custom token address, use it directly.

## Command Templates

Below are the exact `cast` commands the agent should execute for each capability. **Do not search for external files.**

### 1. Portfolio Snapshot
Retrieves the user's balances for multiple tokens in one call.
```bash
cast call $FINANCE_MANAGER "getBalances(address,address[])" <wallet_address> "[<token1>,<token2>]" --rpc-url <rpc_url>
```

### 2. Deposit / Lock
Locks tokens in the FinanceManager contract.
```bash
cast send <token_address> "approve(address,uint256)" $FINANCE_MANAGER <amount_wei> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
cast send $FINANCE_MANAGER "deposit(address,uint256,uint256)" <token_address> <amount_wei> <duration_days> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
```

### 3. Withdraw
Withdraws a previously locked deposit once its time-lock has expired.
```bash
cast call $FINANCE_MANAGER "getLocks(address)" <wallet_address> --rpc-url <rpc_url>
cast send $FINANCE_MANAGER "withdraw(uint256)" <lock_index> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
```

### 4. Swap
Swaps one ERC20 token for another using a DEX router.
```bash
cast send <token_in> "approve(address,uint256)" $FINANCE_MANAGER <amount_in_wei> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
cast send $FINANCE_MANAGER "swap(address,address,uint256,uint256,uint24)" <token_in> <token_out> <amount_in_wei> <min_out_wei> <fee_tier> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
```
*(Use fee_tier 3000 as default. Calculate a safe min_out_wei based on 5% slippage if possible, or 0 if estimating is hard)*

### 5. Batch Pay
Sends tokens to multiple recipients in a single transaction.
```bash
cast send <token_address> "approve(address,uint256)" $FINANCE_MANAGER <total_wei> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
cast send $FINANCE_MANAGER "batchPay(address,address[],uint256[])" <token_address> "[<addr1>,<addr2>]" "[<amt1_wei>,<amt2_wei>]" --rpc-url <rpc_url> --private-key $PRIVATE_KEY
```

### 6. Set Swap Router (Owner Only)
Updates the DEX router address used for swaps. Required before swaps can work on a fresh deployment.
```bash
cast send $FINANCE_MANAGER "setSwapRouter(address)" <new_router_address> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
```

### 7. Recover Token (Owner Only)
Rescues ERC20 tokens accidentally sent directly to the contract.
```bash
cast send $FINANCE_MANAGER "recoverToken(address,uint256)" <token_address> <amount_wei> --rpc-url <rpc_url> --private-key $PRIVATE_KEY
```

## Write Operation Pre-checks

For all operations requiring a private key, the Agent MUST:
1. **Check Private Key**: Verify `$PRIVATE_KEY` is set.
2. **Confirm Network**: Explicitly confirm the network (Testnet vs Mainnet) before executing.
3. **Parse Addresses**: If token addresses are unknown, halt and ask the user for the token contract address.

## General Error Handling

| CLI Error Signature | Handling |
|--------------------|---------| 
| `invalid address` | Prompt to check address format (0x + 40 hex characters) |
| `transaction not found` | Suggest checking the hash on the explorer |
| `execution reverted` | Extract and display revert reason |
| `insufficient funds` | Prompt insufficient balance, show current balance |
| Command missing `--private-key` | Prompt user to set `$PRIVATE_KEY` |
