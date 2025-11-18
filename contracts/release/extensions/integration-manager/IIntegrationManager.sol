// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

interface IIntegrationManager {
    enum SpendAssetsHandleType {
        None,
        Transfer,
        Approve
    }

    function callOnIntegration(bytes calldata, bytes calldata) external returns (bytes memory);
}
