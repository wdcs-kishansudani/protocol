// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

contract AllowedAdaptersPolicyMock {
    address[] public allowedAdapters;

    function addAdapters(address[] memory _adapters) external {
        for (uint256 i = 0; i < _adapters.length; i++) {
            allowedAdapters.push(_adapters[i]);
        }
    }

    function isAdapterAllowed(address _adapter) external view returns (bool) {
        for (uint256 i = 0; i < allowedAdapters.length; i++) {
            if (allowedAdapters[i] == _adapter) {
                return true;
            }
        }
        return false;
    }
}
