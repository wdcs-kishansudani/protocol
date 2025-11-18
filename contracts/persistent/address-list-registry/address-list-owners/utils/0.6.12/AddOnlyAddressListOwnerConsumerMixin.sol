// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {IAddressListRegistry} from "../../../../IAddressListRegistry.sol";

abstract contract AddOnlyAddressListOwnerConsumerMixin {
    IAddressListRegistry internal immutable ADDRESS_LIST_REGISTRY;
    uint256 internal immutable ADDRESS_LIST_ID;

    constructor(address _addressListRegistry, uint256 _addressListId) public {
        ADDRESS_LIST_REGISTRY = IAddressListRegistry(_addressListRegistry);
        ADDRESS_LIST_ID = _addressListId;
    }

    function __validateAndAddListItemIfUnregistered(address _item) internal {
        // In a live Enzyme environment, adding a new aToken to the list would be a separate
        // owner-privileged transaction. For the purposes of this standalone package, we simply
        // validate that the aToken is already on the list.
        require(
            ADDRESS_LIST_REGISTRY.isAddressOnList(ADDRESS_LIST_ID, _item),
            "Item not on address list"
        );
    }
}
