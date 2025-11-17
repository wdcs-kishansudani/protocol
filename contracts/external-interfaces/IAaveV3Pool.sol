// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

interface IAaveV3Pool {
    function supply(address _underlying, uint256 _amount, address _to, uint16 _referralCode) external;

    function withdraw(address _underlying, uint256 _amount, address _to) external returns (uint256);
}
