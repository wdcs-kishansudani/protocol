// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {AaveV3Adapter} from "contracts/release/extensions/integration-manager/integrations/adapters/AaveV3Adapter.sol";

/// @title DeployAaveV3Adapter
/// @notice A Foundry script to deploy the AaveV3Adapter contract.
/// @dev This script reads configuration from environment variables.
///
/// To run this script, first set the required environment variables in your .env file:
///
/// PRIVATE_KEY=<Your deployer private key>
/// INTEGRATION_MANAGER=<Address of the IntegrationManager>
/// ADDRESS_LIST_REGISTRY=<Address of the AddressListRegistry>
/// AAVE_V3_POOL=<Address of the Aave V3 Pool>
/// A_TOKEN_LIST_ID=<ID of the aToken address list>
/// AAVE_REFERRAL_CODE=<Your Aave referral code (optional, defaults to 0)>
///
/// Then, run the script with:
/// forge script script/DeployAaveV3Adapter.s.sol:DeployAaveV3Adapter --rpc-url <your_rpc_url> --broadcast

contract DeployAaveV3Adapter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address integrationManager = vm.envAddress("INTEGRATION_MANAGER");
        address addressListRegistry = vm.envAddress("ADDRESS_LIST_REGISTRY");
        address aaveV3Pool = vm.envAddress("AAVE_V3_POOL");
        uint256 aTokenListId = vm.envUint("A_TOKEN_LIST_ID");
        uint16 referralCode = uint16(vm.envUint("AAVE_REFERRAL_CODE"));

        vm.startBroadcast(deployerPrivateKey);

        AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
            integrationManager,
            addressListRegistry,
            aTokenListId,
            aaveV3Pool,
            referralCode
        );

        console.log("AaveV3Adapter deployed to:", address(aaveV3Adapter));

        vm.stopBroadcast();
    }
}
