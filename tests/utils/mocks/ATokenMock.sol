// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IAaveAToken} from "contracts/external-interfaces/IAaveAToken.sol";

contract ATokenMock is ERC20, IAaveAToken {
    address public immutable UNDERLYING_ASSET_ADDRESS;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        UNDERLYING_ASSET_ADDRESS = _underlying;
    }
}
