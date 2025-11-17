// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {IAaveV3Pool} from "../../../../../../../external-interfaces/IAaveV3Pool.sol";
import {AssetHelpers} from "../../../../../../../utils/0.6.12/AssetHelpers.sol";

abstract contract AaveV3ActionsMixin is AssetHelpers {
    IAaveV3Pool internal immutable AAVE_V3_POOL_CONTRACT;
    uint16 internal immutable AAVE_V3_REFERRAL_CODE;

    constructor(address _pool, uint16 _referralCode) public {
        AAVE_V3_POOL_CONTRACT = IAaveV3Pool(_pool);
        AAVE_V3_REFERRAL_CODE = _referralCode;
    }

    function __aaveV3Lend(address _recipient, address _underlying, uint256 _amount) internal {
        __approveAssetMaxAsNeeded({_asset: _underlying, _target: address(AAVE_V3_POOL_CONTRACT), _neededAmount: _amount});

        AAVE_V3_POOL_CONTRACT.supply({
            _underlying: _underlying,
            _amount: _amount,
            _to: _recipient,
            _referralCode: AAVE_V3_REFERRAL_CODE
        });
    }

    function __aaveV3Redeem(address _recipient, address _underlying, uint256 _amount) internal {
        AAVE_V3_POOL_CONTRACT.withdraw({_underlying: _underlying, _amount: _amount, _to: _recipient});
    }
}
