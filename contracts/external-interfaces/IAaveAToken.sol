// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

interface IAaveAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}
