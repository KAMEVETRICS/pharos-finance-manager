// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./FinanceManager.sol";

/// @notice Deploy FinanceManager to Pharos Network
/// 
/// Usage:
///   forge script script/Deploy.s.sol \
///     --rpc-url $RPC_URL \
///     --private-key $PRIVATE_KEY \
///     --broadcast \
///     --verify \
///     --verifier blockscout \
///     --verifier-url https://api.socialscan.io/pharos-testnet/v1/explorer/command_api/contract
///
/// After deployment, set:
///   export FINANCE_MANAGER=<deployed_address>

contract DeployFinanceManager is Script {

    // ── Update these before deploying ──────────────────────────
    // Pharos Testnet (688689): TBD — set a live DEX router when available
    // Pharos Mainnet (1672):   TBD — set a live DEX router when available
    // Using a dummy burn address because the router is not yet available on Atlantic testnet.
    address constant SWAP_ROUTER = 0x000000000000000000000000000000000000dEaD;

    function run() external {
        // require(SWAP_ROUTER != address(0), "Set SWAP_ROUTER address first");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying FinanceManager...");
        console.log("  Deployer:    ", deployer);
        console.log("  Swap Router: ", SWAP_ROUTER);
        console.log("  Chain ID:    ", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        FinanceManager fm = new FinanceManager(SWAP_ROUTER);

        vm.stopBroadcast();

        console.log("FinanceManager deployed at:", address(fm));
        console.log("Run: export FINANCE_MANAGER=", address(fm));
    }
}
