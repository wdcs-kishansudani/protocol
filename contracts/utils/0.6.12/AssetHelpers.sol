// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {IERC20} from "openzeppelin-solc-0.6/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-solc-0.6/token/ERC20/SafeERC20.sol";

abstract contract AssetHelpers {
    using SafeERC20 for IERC20;

    function __approveAssetMaxAsNeeded(address _asset, address _target, uint256 _neededAmount) internal {
        if (_neededAmount > 0 && IERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            IERC20(_asset).safeApprove(_target, 0);
            IERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }
}
