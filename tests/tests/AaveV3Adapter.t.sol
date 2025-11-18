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

contract AaveV3AdapterDetailedTest is Test {
    AaveV3Adapter public aaveV3Adapter;
    IntegrationManagerMock public integrationManager;
    AddressListRegistryMock public addressListRegistry;
    AaveV3PoolMock public aaveV3Pool;
    ATokenMock public aToken;
    ERC20Mock public underlying;

    address public constant VAULT_PROXY = address(0x123);
    uint256 public constant A_TOKEN_LIST_ID = 1;
    uint256 public constant INITIAL_FUNDING = 1000e18;

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

        underlying.mint(VAULT_PROXY, INITIAL_FUNDING);
        aToken.mint(address(aaveV3Pool), INITIAL_FUNDING); // Pool needs aTokens to send back
    }

    // --- SUCCESS CASES ---

    function testLend_Success() public {
        uint256 lendAmount = 100e18;

        uint256 beforeBalanceUnderlying = underlying.balanceOf(VAULT_PROXY);
        uint256 beforeBalanceAToken = aToken.balanceOf(VAULT_PROXY);

        // Prepare calldata
        address[] memory spendAssets = new address[](1);
        spendAssets[0] = address(underlying);
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = lendAmount;
        address[] memory incomingAssets = new address[](1);
        incomingAssets[0] = address(aToken);

        bytes memory actionData = abi.encode(address(aToken), lendAmount);
        bytes memory assetData = abi.encode(spendAssets, spendAssetAmounts, incomingAssets);

        // Execute
        vm.prank(address(integrationManager));
        aaveV3Adapter.lend(VAULT_PROXY, actionData, assetData);

        // Assert
        uint256 afterBalanceUnderlying = underlying.balanceOf(VAULT_PROXY);
        uint256 afterBalanceAToken = aToken.balanceOf(VAULT_PROXY);

        assertEq(afterBalanceUnderlying, beforeBalanceUnderlying - lendAmount, "Underlying balance should decrease");
        assertEq(afterBalanceAToken, beforeBalanceAToken + lendAmount, "aToken balance should increase");
        assertEq(aaveV3Pool.supplied(address(underlying), VAULT_PROXY), lendAmount, "Pool should record the supply");
    }

    function testRedeem_Success() public {
        uint256 lendAmount = 200e18;
        uint256 redeemAmount = 50e18;

        // Pre-fund the vault with aTokens for the redeem operation
        aToken.mint(VAULT_PROXY, lendAmount);

        uint256 beforeBalanceUnderlying = underlying.balanceOf(VAULT_PROXY);
        uint256 beforeBalanceAToken = aToken.balanceOf(VAULT_PROXY);

        // Prepare calldata
        address[] memory spendAssets = new address[](1);
        spendAssets[0] = address(aToken);
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = redeemAmount;
        address[] memory incomingAssets = new address[](1);
        incomingAssets[0] = address(underlying);

        bytes memory actionData = abi.encode(address(aToken), redeemAmount);
        bytes memory assetData = abi.encode(spendAssets, spendAssetAmounts, incomingAssets);

        // Execute
        vm.prank(address(integrationManager));
        aaveV3Adapter.redeem(VAULT_PROXY, actionData, assetData);

        // Assert
        uint256 afterBalanceUnderlying = underlying.balanceOf(VAULT_PROXY);
        uint256 afterBalanceAToken = aToken.balanceOf(VAULT_PROXY);

        assertEq(afterBalanceUnderlying, beforeBalanceUnderlying + redeemAmount, "Underlying balance should increase");
        assertEq(afterBalanceAToken, beforeBalanceAToken - redeemAmount, "aToken balance should decrease");
        assertEq(aaveV3Pool.withdrawn(address(underlying), VAULT_PROXY), redeemAmount, "Pool should record the withdrawal");
    }

    // --- FAILURE CASES ---

    function testLend_RevertsIfAmountIsZero() public {
        uint256 lendAmount = 0;

        address[] memory spendAssets = new address[](1);
        spendAssets[0] = address(underlying);
        uint256[] memory spendAssetAmounts = new uint256[](1);
        spendAssetAmounts[0] = lendAmount;
        // ... and so on

        bytes memory actionData = abi.encode(address(aToken), lendAmount);
        bytes memory assetData = abi.encode(new address[](0), new uint256[](0), new address[](0));

        vm.prank(address(integrationManager));
        vm.expectRevert(); // Exact revert message depends on Aave's implementation, but it should revert.
        aaveV3Adapter.lend(VAULT_PROXY, actionData, assetData);
    }

    function testLend_RevertsIfATokenNotRegistered() public {
        uint256 lendAmount = 100e18;
        ATokenMock unregisteredAToken = new ATokenMock(address(underlying), "Unregistered", "UNR");

        bytes memory actionData = abi.encode(address(unregisteredAToken), lendAmount);
        bytes memory assetData = abi.encode(new address[](0), new uint256[](0), new address[](0));

        vm.prank(address(integrationManager));
        vm.expectRevert("Item not on address list");
        aaveV3Adapter.lend(VAULT_PROXY, actionData, assetData);
    }

    function testParseAssets_RevertsForInvalidSelector() public {
        bytes4 invalidSelector = bytes4(keccak256("invalidSelector()"));
        vm.expectRevert("parseAssetsForAction: _selector invalid");
        aaveV3Adapter.parseAssetsForAction(VAULT_PROXY, invalidSelector, "");
    }
}
