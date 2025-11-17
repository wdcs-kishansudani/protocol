// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IIntegrationManager} from "contracts/release/extensions/integration-manager/IIntegrationManager.sol";

contract IntegrationManagerMock is IIntegrationManager {
    function callOnIntegration(bytes calldata, bytes calldata) external returns (bytes memory) {
        // Mock implementation
        return "";
    }
}
