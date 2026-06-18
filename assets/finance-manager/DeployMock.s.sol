// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./MockERC20.sol";

contract DeployMock is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        MockERC20 token = new MockERC20("Mock USDC", "mUSDC", 1000000 * 10**18);
        vm.stopBroadcast();
        console.log("MockERC20 deployed at:", address(token));
    }
}
