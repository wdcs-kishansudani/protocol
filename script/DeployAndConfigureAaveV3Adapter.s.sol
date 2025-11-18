// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {AaveV3Adapter} from "contracts/release/extensions/integration-manager/integrations/adapters/AaveV3Adapter.sol";
import {AllowedAdaptersPolicyMock} from "tests/utils/mocks/AllowedAdaptersPolicyMock.sol";

/// @title DeployAndConfigureAaveV3Adapter
/// @notice A Foundry script to deploy the AaveV3Adapter and configure it with a mock policy.
/// @dev This script demonstrates the full setup process: deploying the adapter and authorizing it for a fund.
///
/// To run this script, set the required environment variables in your .env file:
///
/// PRIVATE_KEY=<Your deployer private key>
/// INTEGRATION_MANAGER=<Address of the IntegrationManager>
/// ADDRESS_LIST_REGISTRY=<Address of the AddressListRegistry>
/// AAVE_V3_POOL=<Address of the Aave V3 Pool>
/// A_TOKEN_LIST_ID=<ID of the aToken address list>
///
/// Then, run the script with:
/// forge script script/DeployAndConfigureAaveV3Adapter.s.sol:DeployAndConfigureAaveV3Adapter --rpc-url <your_rpc_url> --broadcast

contract DeployAndConfigureAaveV3Adapter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address integrationManager = vm.envAddress("INTEGRATION_MANAGER");
        address addressListRegistry = vm.envAddress("ADDRESS_LIST_REGISTRY");
        address aaveV3Pool = vm.envAddress("AAVE_V3_POOL");
        uint256 aTokenListId = vm.envUint("A_TOKEN_LIST_ID");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the AaveV3Adapter
        AaveV3Adapter aaveV3Adapter = new AaveV3Adapter(
            integrationManager,
            addressListRegistry,
            aTokenListId,
            aaveV3Pool,
            0
        );
        console.log("AaveV3Adapter deployed to:", address(aaveV3Adapter));

        // 2. Deploy a mock AllowedAdaptersPolicy for a fund
        AllowedAdaptersPolicyMock policy = new AllowedAdaptersPolicyMock();
        console.log("AllowedAdaptersPolicyMock deployed to:", address(policy));

        // 3. Authorize the AaveV3Adapter with the policy
        address[] memory adaptersToAdd = new address[](1);
        adaptersToAdd[0] = address(aaveV3Adapter);
        policy.addAdapters(adaptersToAdd);
        console.log("AaveV3Adapter has been authorized with the policy.");

        // 4. Verify the adapter is now allowed
        bool isAllowed = policy.isAdapterAllowed(address(aaveV3Adapter));
        require(isAllowed, "Configuration failed: Adapter is not allowed after authorization.");
        console.log("Verification successful: The adapter is correctly authorized in the policy.");

        vm.stopBroadcast();
    }
}
