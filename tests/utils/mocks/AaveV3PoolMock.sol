// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAaveV3Pool} from "contracts/external-interfaces/IAaveV3Pool.sol";

contract AaveV3PoolMock is IAaveV3Pool {
    mapping(address => mapping(address => uint256)) public supplied;
    mapping(address => mapping(address => uint256)) public withdrawn;

    function supply(address _underlying, uint256 _amount, address _to, uint16) external {
        supplied[_underlying][_to] += _amount;
    }

    function withdraw(address _underlying, uint256 _amount, address _to) external returns (uint256) {
        withdrawn[_underlying][_to] += _amount;
        return _amount;
    }
}
