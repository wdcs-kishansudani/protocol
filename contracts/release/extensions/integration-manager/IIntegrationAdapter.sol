// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

import {IIntegrationManager} from "./IIntegrationManager.sol";

interface IIntegrationAdapter {
    function parseAssetsForAction(
        address vaultProxy,
        bytes4 selector,
        bytes calldata actionData
    )
        external
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets,
            uint256[] memory minIncomingAssetAmounts
        );
}
