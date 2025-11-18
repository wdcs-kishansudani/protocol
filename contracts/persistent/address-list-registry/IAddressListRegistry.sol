// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

interface IAddressListRegistry {
    function isAddressOnList(uint256 _listId, address _who) external view returns (bool);
}
