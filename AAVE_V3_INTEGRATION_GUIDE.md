# Enzyme Protocol: Aave V3 Integration Guide

> **Disclaimer:** This is a standalone developer package designed to demonstrate the integration of Aave V3 with the Enzyme protocol. It includes simplified versions of the necessary Enzyme contracts and interfaces for educational and testing purposes. This package is not intended to be merged directly into the main Enzyme protocol repository.

This document provides a comprehensive guide for developers on integrating, deploying, and interacting with the Aave V3 protocol through the Enzyme Finance interface. It is intended for both novice and experienced blockchain engineers seeking to leverage Aave V3's liquidity within the Enzyme ecosystem.

## Table of Contents

- [Architectural Overview](#architectural-overview)
- [Contract Roles and Dependencies](#contract-roles-and-dependencies)
- [Deployment Process](#deployment-process)
  - [Prerequisites](#prerequisites)
  - [Deployment Steps](#deployment-steps)
- [Interacting with the `AaveV3Adapter`](#interacting-with-the-aavev3adapter)
  - [Lending](#lending)
  - [Redeeming](#redeeming)
- [Use in a Foundry Test Environment](#use-in-a-foundry-test-environment)
- [Multi-Network Deployment](#multi-network-deployment)
- [File Manifest](#file-manifest)

## Architectural Overview

The Aave V3 integration is designed to be modular and upgradeable, fitting seamlessly into Enzyme's extension-based architecture. The core of the integration is the `AaveV3Adapter.sol` contract, which acts as a bridge between the Enzyme `IntegrationManager` and the Aave V3 protocol. This adapter exposes two primary functions—`lend` and `redeem`—that allow Enzyme vaults to supply and withdraw assets from Aave's liquidity pools.

The `AaveV3Adapter` inherits from two base contracts:

- **`AaveAdapterBase.sol`**: Provides common functionality for Aave integrations, including asset parsing, `IntegrationManager` interaction, and handling of `aToken` precision with a `ROUNDING_BUFFER`.
- **`AaveV3ActionsMixin.sol`**: Contains the low-level logic for interacting with the Aave V3 `Pool` contract, executing `supply` and `withdraw` calls.

This architecture ensures that the integration is both robust and easy to maintain, while also providing a clear separation of concerns between the Enzyme-specific logic and the Aave V3 interactions.

## Contract Roles and Dependencies

- **`AaveV3Adapter.sol`**: The main integration contract that connects Enzyme to Aave V3. It is responsible for handling `lend` and `redeem` actions initiated by an Enzyme vault.
- **`IntegrationManager.sol`**: A core Enzyme contract that manages all external protocol integrations. The `AaveV3Adapter` must be registered with the `IntegrationManager` to be usable by Enzyme vaults.
- **`AddressListRegistry.sol`**: An Enzyme contract that maintains lists of registered addresses. The `AaveV3Adapter` uses this to validate `aTokens`.
- **Aave V3 `Pool`**: The central Aave V3 contract that facilitates lending and borrowing. The `AaveV3Adapter` interacts directly with this contract to perform its functions.
- **`aTokens`**: Interest-bearing tokens minted by Aave V3 that represent a user's supplied assets. These are the assets that an Enzyme vault receives when lending and spends when redeeming.

## Deployment Process

Deploying the `AaveV3Adapter` requires a few prerequisites and a straightforward deployment script.

### Prerequisites

- An existing deployment of the Enzyme protocol, including the `IntegrationManager` and `AddressListRegistry`.
- The address of the Aave V3 `Pool` contract on the target network.
- A pre-configured `AddressList` for `aTokens`, or the ID of an existing one.

### Deployment Steps

1. **Deploy `AaveV3Adapter.sol`**: Deploy the adapter contract with the following constructor arguments:
   - `_integrationManager`: The address of the `IntegrationManager`.
   - `_addressListRegistry`: The address of the `AddressListRegistry`.
   - `_aTokenListId`: The ID of the `AddressList` for `aTokens`.
   - `_pool`: The address of the Aave V3 `Pool` contract.
   - `_referralCode`: An optional referral code (defaults to 0).

2. **Register with `IntegrationManager`**: After deployment, the adapter must be registered with the `IntegrationManager` to make it available to Enzyme vaults. This is typically done by calling a registration function on the `IntegrationManager` or a related contract.

3. **Whitelist `aTokens`**: The `aTokens` that will be used must be whitelisted in the `AddressList` specified by `_aTokenListId`.

## Interacting with the `AaveV3Adapter`

Once deployed and registered, the `AaveV3Adapter` can be used by Enzyme vaults to lend and redeem assets.

### Lending

To lend an asset to Aave V3, a fund manager calls `callOnIntegration` on the `ComptrollerProxy` with the following parameters:

- **`_adapter`**: The address of the `AaveV3Adapter`.
- **`_selector`**: The function selector for `lend(address,bytes,bytes)`.
- **`_actionData`**: ABI-encoded `(address aToken, uint256 amount)`, where `aToken` is the `aToken` to be received and `amount` is the amount of the underlying asset to lend.

### Redeeming

To redeem an underlying asset from Aave V3, a fund manager calls `callOnIntegration` on the `ComptrollerProxy` with the following parameters:

- **`_adapter`**: The address of the `AaveV3Adapter`.
- **`_selector`**: The function selector for `redeem(address,bytes,bytes)`.
- **`_actionData`**: ABI-encoded `(address aToken, uint256 amount)`, where `aToken` is the `aToken` to be spent and `amount` is the amount of the `aToken` to redeem.

## Use in a Foundry Test Environment

The `AaveV3Adapter` can be tested in a local Foundry environment using mock contracts for its dependencies. The test suite should include:

- A mock `IntegrationManager` to simulate calls from an Enzyme vault.
- A mock Aave V3 `Pool` to verify that the correct functions are called with the expected parameters.
- Tests for both `lend` and `redeem` to ensure that asset parsing and interaction logic are working correctly.

## Multi-Network Deployment

To deploy the `AaveV3Adapter` to different networks, you will need to update the constructor arguments with the appropriate addresses for each network. This can be managed through a configuration file or environment variables.

### Required Addresses

- **`IntegrationManager`**: The address of the `IntegrationManager` on the target network.
- **`AddressListRegistry`**: The address of the `AddressListRegistry` on the target network.
- **Aave V3 `Pool`**: The address of the Aave V3 `Pool` contract on the target network.

By following this guide, a development team can confidently deploy, test, and interact with the Aave V3 protocol through the Enzyme Finance interface.

## File Manifest

This developer package includes the following files:

- **`AAVE_V3_INTEGRATION_GUIDE.md`**: This document, providing a comprehensive overview of the Aave V3 integration.
- **`MULTI_NETWORK_DEPLOYMENT_GUIDE.md`**: A guide to configuring the deployment for multiple networks.
- **`script/DeployAaveV3Adapter.s.sol`**: A Foundry script for deploying the `AaveV3Adapter`.
- **`tests/tests/AaveV3Adapter.t.sol`**: A Foundry test suite for the `AaveV3Adapter`.
- **`tests/utils/mocks/`**: A directory containing mock contracts for testing purposes.
- **`contracts/`**: A directory containing all the necessary contracts and interfaces for the Aave V3 integration.
