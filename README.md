# Pharos Finance Manager Skill

![Solidity](https://img.shields.io/badge/Solidity-100%25-363636)
![Pharos](https://img.shields.io/badge/Network-Pharos-blueviolet)
![Skill Engine](https://img.shields.io/badge/Pharos%20Skill%20Engine-v0.1.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

The Finance Manager Skill is a developer toolkit for the Pharos blockchain, designed to allow AI agents (and human operators) to perform on-chain asset management operations. It handles deposits/locks, token swaps, batch payments, and portfolio snapshots through a single deployed `FinanceManager` contract.

## Why this matters for Pharos + Agent Economy

- Autonomous agents need to manage treasuries securely. This skill gives them the ability to lock capital, check their portfolio, and batch pay other agents or humans.
- Reduces friction for AI-native workflows that require trading, swapping, and asset locking natively on the Pharos network.

## Installation

Agents and developers can easily install this skill into their Pharos Agent Centre setup:

```bash
npx skills add https://github.com/KAMEVETRICS/pharos-finance-manager
```

## Prerequisites

1. **Foundry Installed**: This skill relies heavily on `cast` and `forge`.
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   source ~/.zshenv && foundryup
   ```
2. **Private Key**: Required for signing transactions.
   ```bash
   export PRIVATE_KEY=0xYourPrivateKeyHere
   ```
3. **Contract Deployed**: You must deploy the Finance Manager first or use an existing one.
   ```bash
   export FINANCE_MANAGER=0xDeployedAddressHere
   ```

## Agent Policy / Expected Behavior

This skill is designed to be invoked automatically by an AI agent when managing assets.
- 🛑 **BLOCK**: Agents should reject calls to transfer tokens out of the treasury to unknown, unverified addresses unless explicitly confirmed by the user.
- ⚠️ **WARN**: Warn the user before finalizing swaps with high slippage.
- ✅ **ALLOW**: Provide immediate portfolio snapshots without asking for permissions.

## Quickstart

Once the prerequisites are set, you can invoke the skill via an AI agent by using natural language:

**Example Agent Prompts:**
- "Deploy the finance manager to the testnet."
- "Lock 100 USDC for 30 days."
- "Swap 50 WETH for USDC."
- "Check my portfolio balances."
- "Batch pay 100 USDC to 0xAlice and 0xBob."

## Documentation

- **[SKILL.md](./SKILL.md)**: The primary entry point for AI agents. Contains the Capability Index and general guidelines.
- **[Finance Manager Operations](./references/finance-manager.md)**: The detailed command templates for each supported action.
- **[Tokens & Networks](./assets/)**: Address dictionaries for supported networks and tokens.
