// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {SafeMath} from "openzeppelin-solc-0.6/math/SafeMath.sol";
import {AddOnlyAddressListOwnerConsumerMixin} from
    "../../../../../../../persistent/address-list-registry/address-list-owners/utils/0.6.12/AddOnlyAddressListOwnerConsumerMixin.sol";
import {IAaveAToken} from "../../../../../../../external-interfaces/IAaveAToken.sol";
import {IIntegrationManager} from "../../../../IIntegrationManager.sol";
import {AdapterBase} from "../AdapterBase.sol";

abstract contract AaveAdapterBase is AdapterBase, AddOnlyAddressListOwnerConsumerMixin {
    using SafeMath for uint256;

    uint256 private constant ROUNDING_BUFFER = 2;

    constructor(address _integrationManager, address _addressListRegistry, uint256 _aTokenListId)
        public
        AdapterBase(_integrationManager)
        AddOnlyAddressListOwnerConsumerMixin(_addressListRegistry, _aTokenListId)
    {}

    function __lend(address _vaultProxy, address _underlying, uint256 _amount) internal virtual;

    function __redeem(address _vaultProxy, address _underlying, uint256 _amount) internal virtual;

    function lend(address _vaultProxy, bytes calldata, bytes calldata _assetData) external onlyIntegrationManager {
        (address[] memory spendAssets, uint256[] memory spendAssetAmounts, address[] memory incomingAssets) =
            __decodeAssetData(_assetData);

        __validateAndAddListItemIfUnregistered(incomingAssets[0]);

        __lend({_vaultProxy: _vaultProxy, _underlying: spendAssets[0], _amount: spendAssetAmounts[0]});
    }

    function redeem(address _vaultProxy, bytes calldata, bytes calldata _assetData) external onlyIntegrationManager {
        (address[] memory spendAssets, uint256[] memory spendAssetAmounts, address[] memory incomingAssets) =
            __decodeAssetData(_assetData);

        __validateAndAddListItemIfUnregistered(spendAssets[0]);

        __redeem({_vaultProxy: _vaultProxy, _underlying: incomingAssets[0], _amount: spendAssetAmounts[0]});
    }

    function parseAssetsForAction(address, bytes4 _selector, bytes calldata _actionData)
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType,
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        (address aToken, uint256 amount) = __decodeCallArgs(_actionData);

        address[] memory spendAssets = new address[](1);
        spendAssets[0] = IAaveAToken(aToken).UNDERLYING_ASSET_ADDRESS();
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = amount;

        address[] memory incomingAssets = new address[](1);
        incomingAssets[0] = aToken;
        uint256[] memory minIncomingAssetAmounts = new uint256[](1);
        minIncomingAssetAmounts[0] = amount.sub(ROUNDING_BUFFER);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets,
            spendAssetAmounts,
            incomingAssets,
            minIncomingAssetAmounts
        );
    }

    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType,
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        (address aToken, uint256 amount) = __decodeCallArgs(_actionData);

        address[] memory spendAssets = new address[](1);
        spendAssets[0] = aToken;
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = amount;

        address[] memory incomingAssets = new address[](1);
        incomingAssets[0] = IAaveAToken(aToken).UNDERLYING_ASSET_ADDRESS();
        uint256[] memory minIncomingAssetAmounts = new uint256[](1);
        minIncomingAssetAmounts[0] = amount.sub(ROUNDING_BUFFER);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets,
            spendAssetAmounts,
            incomingAssets,
            minIncomingAssetAmounts
        );
    }

    function __decodeCallArgs(bytes memory _actionData) private pure returns (address aToken_, uint256 amount_) {
        return abi.decode(_actionData, (address, uint256));
    }
}
