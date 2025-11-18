// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IIntegrationManager} from "contracts/release/extensions/integration-manager/IIntegrationManager.sol";
import {IIntegrationAdapter} from "contracts/release/extensions/integration-manager/IIntegrationAdapter.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title ComptrollerProxyMock
/// @notice Mocks the behavior of a fund's ComptrollerProxy for scripting and testing.
/// @dev This mock simulates holding the fund's assets (like a VaultProxy) and calling the IntegrationManager.
contract ComptrollerProxyMock {
    IIntegrationManager public immutable integrationManager;

    constructor(address _integrationManager) {
        integrationManager = IIntegrationManager(_integrationManager);
    }

    /// @notice Simulates a fund manager calling an integration adapter.
    /// @param _adapter The address of the adapter to call.
    /// @param _selector The function selector of the adapter's method to call.
    /// @param _actionData The encoded data for the specific action.
    function callOnIntegration(
        address _adapter,
        bytes4 _selector,
        bytes calldata _actionData
    ) external {
        // In a real scenario, the ComptrollerProxy would delegatecall to the VaultProxy,
        // which would then call the IntegrationManager. This mock simplifies that flow
        // by calling the IntegrationManager directly.

        // To make this mock behave like a VaultProxy for the adapter's perspective,
        // we temporarily give the IntegrationManager an allowance to spend this contract's tokens.
        // First, we need to parse the assets the adapter will spend.
        (
            ,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            ,

        ) = IIntegrationAdapter(_adapter).parseAssetsForAction(address(this), _selector, _actionData);

        // Approve the IntegrationManager to spend the required assets from this contract.
        for (uint256 i = 0; i < spendAssets.length; i++) {
            IERC20(spendAssets[i]).approve(address(integrationManager), spendAssetAmounts[i]);
        }

        // The IntegrationManager expects the call to come from the VaultProxy (ComptrollerProxy in this case)
        integrationManager.callOnIntegration(address(this), _adapter, _selector, _actionData);
    }
}
