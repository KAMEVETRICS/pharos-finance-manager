// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./FinanceManagerTest.sol";
import "./MockERC20.sol";

contract DeployTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address usdc = vm.envAddress("USDC_ADDR");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy test contract
        FinanceManagerTest fmTest = new FinanceManagerTest(0x000000000000000000000000000000000000dEaD);
        console.log("FinanceManagerTest deployed at:", address(fmTest));
        
        // 2. Approve mock USDC
        MockERC20(usdc).approve(address(fmTest), 100 * 10**18);
        
        // 3. Deposit 100 USDC for 1 second
        fmTest.deposit(usdc, 100 * 10**18, 1);
        console.log("Deposited 100 USDC for 1 second to test contract");
        
        vm.stopBroadcast();
    }
}
