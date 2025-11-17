// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAddressListRegistry} from "contracts/persistent/address-list-registry/IAddressListRegistry.sol";

contract AddressListRegistryMock is IAddressListRegistry {
    mapping(uint256 => mapping(address => bool)) public lists;

    function createAddressList(uint256 _listId) external {
        // Mock implementation
    }

    function addAddressToList(uint256 _listId, address _who) external {
        lists[_listId][_who] = true;
    }

    function removeAddressFromList(uint256 _listId, address _who) external {
        lists[_listId][_who] = false;
    }

    function isAddressOnList(uint256 _listId, address _who) external view returns (bool) {
        return lists[_listId][_who];
    }
}
