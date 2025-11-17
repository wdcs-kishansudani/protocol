// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {AaveV3Adapter} from "contracts/release/extensions/integration-manager/integrations/adapters/AaveV3Adapter.sol";
import {IIntegrationManager} from "contracts/release/extensions/integration-manager/IIntegrationManager.sol";

// Mock Contracts
import {AddressListRegistryMock} from "tests/utils/mocks/AddressListRegistryMock.sol";
import {IntegrationManagerMock} from "tests/utils/mocks/IntegrationManagerMock.sol";
import {AaveV3PoolMock} from "tests/utils/mocks/AaveV3PoolMock.sol";
import {ATokenMock} from "tests/utils/mocks/ATokenMock.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract AaveV3AdapterTest is Test {
    AaveV3Adapter public aaveV3Adapter;
    IntegrationManagerMock public integrationManager;
    AddressListRegistryMock public addressListRegistry;
    AaveV3PoolMock public aaveV3Pool;
    ATokenMock public aToken;
    ERC20Mock public underlying;

    address public constant VAULT_PROXY = address(0x123);
    uint256 public constant A_TOKEN_LIST_ID = 1;

    function setUp() public {
        integrationManager = new IntegrationManagerMock();
        addressListRegistry = new AddressListRegistryMock();
        aaveV3Pool = new AaveV3PoolMock();
        underlying = new ERC20Mock("Underlying Token", "ULT", 18);
        aToken = new ATokenMock(address(underlying), "aToken", "aULT");

        addressListRegistry.createAddressList(A_TOKEN_LIST_ID);
        addressListRegistry.addAddressToList(A_TOKEN_LIST_ID, address(aToken));

        aaveV3Adapter = new AaveV3Adapter(
            address(integrationManager),
            address(addressListRegistry),
            A_TOKEN_LIST_ID,
            address(aaveV3Pool),
            0
        );

        underlying.mint(VAULT_PROXY, 1000e18);
    }

    function testLend() public {
        uint256 lendAmount = 100e18;

        address[] memory spendAssets = new address[](1);
        spendAssets[0] = address(underlying);
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = lendAmount;
        address[] memory incomingAssets = new address[](1);
        incomingAssets[0] = address(aToken);

        bytes memory actionData = abi.encode(address(aToken), lendAmount);
        bytes memory assetData = abi.encode(spendAssets, spendAssetAmounts, incomingAssets);

        vm.startPrank(address(integrationManager));
        aaveV3Adapter.lend(VAULT_PROXY, actionData, assetData);
        vm.stopPrank();

        assertEq(aaveV3Pool.supplied(address(underlying), VAULT_PROXY), lendAmount);
    }

    function testRedeem() public {
        uint256 redeemAmount = 50e18;

        // First, lend some tokens to have a balance to redeem
        testLend();

        address[] memory spendAssets = new address[](1);
        spendAssets[0] = address(aToken);
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = redeemAmount;
        address[] memory incomingAssets = new address[](1);
        incomingAssets[0] = address(underlying);

        bytes memory actionData = abi.encode(address(aToken), redeemAmount);
        bytes memory assetData = abi.encode(spendAssets, spendAssetAmounts, incomingAssets);

        vm.startPrank(address(integrationManager));
        aaveV3Adapter.redeem(VAULT_PROXY, actionData, assetData);
        vm.stopPrank();

        assertEq(aaveV3Pool.withdrawn(address(underlying), VAULT_PROXY), redeemAmount);
    }
}
