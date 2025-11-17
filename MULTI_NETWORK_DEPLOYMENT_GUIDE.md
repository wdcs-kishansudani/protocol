# AaveV3Adapter: Multi-Network Deployment Guide

This guide provides instructions on how to configure the deployment of the `AaveV3Adapter` for various networks, including local development, testnets, and mainnet.

## Table of Contents

- [Introduction](#introduction)
- [Configuration via Environment Variables](#configuration-via-environment-variables)
- [Network-Specific Contract Addresses](#network-specific-contract-addresses)
  - [Finding Aave V3 Addresses](#finding-aave-v3-addresses)
- [Example `.env` Configuration](#example-env-configuration)
- [Deployment Command](#deployment-command)

## Introduction

The `DeployAaveV3Adapter.s.sol` Foundry script is designed to be network-agnostic, reading its configuration from environment variables. This allows you to deploy the adapter to any EVM-compatible chain with a running Aave V3 protocol instance by simply providing the correct contract addresses.

## Configuration via Environment Variables

The deployment script requires the following environment variables to be set in a `.env` file at the root of your project:

- **`PRIVATE_KEY`**: The private key of the account that will be used to deploy the contract.
- **`INTEGRATION_MANAGER`**: The address of the Enzyme `IntegrationManager` contract on the target network.
- **`ADDRESS_LIST_REGISTRY`**: The address of the Enzyme `AddressListRegistry` contract on the target network.
- **`AAVE_V3_POOL`**: The address of the Aave V3 `Pool` contract on the target network.
- **`A_TOKEN_LIST_ID`**: The ID of the `AddressList` in the `AddressListRegistry` that will be used to whitelist `aTokens`.
- **`AAVE_REFERRAL_CODE`**: An optional referral code for Aave. Defaults to `0` if not provided.

## Network-Specific Contract Addresses

To deploy the adapter, you will need to find the addresses of the `IntegrationManager`, `AddressListRegistry`, and Aave V3 `Pool` contracts for your target network.

### Finding Aave V3 Addresses

The official Aave documentation is the best source for finding the correct `Pool` contract address for each network. You can typically find this information in their developer documentation or by looking at their deployed contract addresses on a block explorer.

For example, on Ethereum Mainnet, the Aave V3 `Pool` address is `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2`.

## Example `.env` Configuration

Here is an example of what your `.env` file might look like for deploying to Ethereum Mainnet:

```
# .env

# Deployer Configuration
PRIVATE_KEY=your_deployer_private_key

# Enzyme Protocol Addresses (Mainnet)
INTEGRATION_MANAGER=0x...
ADDRESS_LIST_REGISTRY=0x...

# Aave V3 Addresses (Mainnet)
AAVE_V3_POOL=0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2

# Adapter Configuration
A_TOKEN_LIST_ID=1
AAVE_REFERRAL_CODE=0
```

## Deployment Command

Once you have configured your `.env` file with the correct addresses for your target network, you can run the deployment script using the following command:

```bash
forge script script/DeployAaveV3Adapter.s.sol:DeployAaveV3Adapter --rpc-url <your_rpc_url> --broadcast
```

Replace `<your_rpc_url>` with the RPC URL for your target network. This command will deploy the `AaveV3Adapter` and log its address to the console.
