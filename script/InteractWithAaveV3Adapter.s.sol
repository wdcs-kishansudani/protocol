// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ComptrollerProxyMock} from "tests/utils/mocks/ComptrollerProxyMock.sol";
import {AaveV3Adapter} from "contracts/release/extensions/integration-manager/integrations/adapters/AaveV3Adapter.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {ATokenMock} from "tests/utils/mocks/ATokenMock.sol";

/// @title InteractWithAaveV3Adapter
/// @notice A Foundry script to demonstrate how to interact with the AaveV3Adapter.
/// @dev This script simulates a fund manager calling the `lend` and `redeem` functions.
///
/// To run this script, set the required environment variables in your .env file:
///
/// PRIVATE_KEY=<Your private key>
/// COMPTROLLER_PROXY=<Address of the ComptrollerProxyMock>
/// AAVE_V3_ADAPTER=<Address of the deployed AaveV3Adapter>
/// UNDERLYING_TOKEN=<Address of the underlying ERC20 token to lend>
/// A_TOKEN=<Address of the corresponding aToken>
///
/// Then, run the script with:
/// forge script script/InteractWithAaveV3Adapter.s.sol:InteractWithAaveV3Adapter --rpc-url <your_rpc_url> --broadcast

contract InteractWithAaveV3Adapter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address comptrollerProxyAddress = vm.envAddress("COMPTROLLER_PROXY");
        address aaveV3AdapterAddress = vm.envAddress("AAVE_V3_ADAPTER");
        address underlyingTokenAddress = vm.envAddress("UNDERLYING_TOKEN");
        address aTokenAddress = vm.envAddress("A_TOKEN");

        ComptrollerProxyMock comptrollerProxy = ComptrollerProxyMock(payable(comptrollerProxyAddress));
        ERC20Mock underlying = ERC20Mock(payable(underlyingTokenAddress));
        ATokenMock aToken = ATokenMock(payable(aTokenAddress));

        vm.startBroadcast(deployerPrivateKey);

        // --- LEND ---
        uint256 lendAmount = 100 * 10 ** 18; // Lend 100 tokens

        // Fund the comptroller proxy with the underlying asset to simulate the fund's holdings
        underlying.mint(comptrollerProxyAddress, lendAmount);
        console.log("ComptrollerProxyMock funded with %s of the underlying token.", lendAmount);

        bytes4 lendSelector = bytes4(keccak256("lend(address,bytes,bytes)"));
        bytes memory lendActionData = abi.encode(aTokenAddress, lendAmount);

        console.log("Executing lend operation...");
        comptrollerProxy.callOnIntegration(aaveV3AdapterAddress, lendSelector, lendActionData);
        console.log("Lend operation successful.");

        // --- REDEEM ---
        uint256 redeemAmount = 50 * 10 ** 18; // Redeem 50 tokens

        // The comptroller proxy now holds aTokens. To redeem, it needs to approve the IntegrationManager.
        // Our mock handles this automatically. We transfer the aTokens to the mock to simulate this state.
        aToken.mint(comptrollerProxyAddress, lendAmount); // Simulate receiving aTokens from the lend call.

        bytes4 redeemSelector = bytes4(keccak256("redeem(address,bytes,bytes)"));
        bytes memory redeemActionData = abi.encode(aTokenAddress, redeemAmount);

        console.log("Executing redeem operation...");
        comptrollerProxy.callOnIntegration(aaveV3AdapterAddress, redeemSelector, redeemActionData);
        console.log("Redeem operation successful.");

        vm.stopBroadcast();
    }
}
