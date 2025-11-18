// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {IIntegrationManager} from "../../../IIntegrationManager.sol";

abstract contract AdapterBase {
    IIntegrationManager internal immutable INTEGRATION_MANAGER;

    bytes4 internal constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 internal constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));

    modifier onlyIntegrationManager() {
        require(msg.sender == address(INTEGRATION_MANAGER), "Only the IntegrationManager can call this function");
        _;
    }

    constructor(address _integrationManager) public {
        INTEGRATION_MANAGER = IIntegrationManager(_integrationManager);
    }

    function parseAssetsForAction(
        address,
        bytes4,
        bytes calldata
    )
        external
        view
        virtual
        returns (
            IIntegrationManager.SpendAssetsHandleType,
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        );

    function __decodeAssetData(bytes calldata _assetData)
        internal
        pure
        returns (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        )
    {
        return abi.decode(_assetData, (address[], uint256[], address[]));
    }
}
