// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./FinanceManager.sol";

/// @notice Interaction examples for FinanceManager
/// These are forge script equivalents of the cast commands in SKILL.md.
/// For agent use, prefer the cast commands directly.

contract InteractFinanceManager is Script {

    FinanceManager fm;

    function setUp() public {
        address contractAddr = vm.envAddress("FINANCE_MANAGER");
        fm = FinanceManager(contractAddr);
    }

    /// forge script script/Interact.s.sol:InteractFinanceManager \
    ///   --sig "depositExample()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
    function depositExample() external {
        address token = vm.envAddress("TOKEN_ADDR");
        uint256 amount = vm.envUint("AMOUNT_WEI");
        uint256 days_ = vm.envUint("DURATION_DAYS");

        vm.startBroadcast();

        // Approve first
        IERC20(token).approve(address(fm), amount);

        // Then deposit
        fm.deposit(token, amount, days_);

        vm.stopBroadcast();
        console.log("Deposited amount:", amount);
        console.log("For days:", days_);
    }

    /// forge script script/Interact.s.sol:InteractFinanceManager \
    ///   --sig "withdrawExample(uint256)" <lockIndex> ...
    function withdrawExample(uint256 lockIndex) external {
        vm.startBroadcast();
        fm.withdraw(lockIndex);
        vm.stopBroadcast();
        console.log("Withdrawn lock index", lockIndex);
    }

    /// forge script script/Interact.s.sol:InteractFinanceManager \
    ///   --sig "snapshotExample()" ...
    function snapshotExample() external view {
        address wallet   = vm.envAddress("WALLET_ADDR");
        address usdc     = vm.envAddress("USDC_ADDR");
        address weth     = vm.envAddress("WETH_ADDR");
        address wbtc     = vm.envAddress("WBTC_ADDR");
        address phrs     = vm.envAddress("PHRS_ADDR");

        address[] memory tokens = new address[](4);
        tokens[0] = usdc;
        tokens[1] = weth;
        tokens[2] = wbtc;
        tokens[3] = phrs;

        uint256[] memory balances = fm.getBalances(wallet, tokens);

        console.log("Portfolio snapshot for", wallet);
        console.log("  USDC:", balances[0]);
        console.log("  WETH:", balances[1]);
        console.log("  WBTC:", balances[2]);
        console.log("  PHRS:", balances[3]);
    }
}
