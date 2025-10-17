# Enzyme Protocol: System Overview

## Core Architecture: Persistent and Release Layers

The Enzyme protocol is built on a sophisticated two-layer architecture designed for robust security and seamless upgradeability. This separation is the key to the protocol's ability to evolve and add new features without disrupting existing funds or requiring asset migrations.

```mermaid
graph TD
    subgraph Persistent Layer
        Dispatcher;
        VaultProxy;
    end
    subgraph Release Layer
        FundDeployer;
        ComptrollerProxy;
        VaultLib;
        FeeManager;
        PolicyManager;
    end
    Dispatcher -- "points to current" --> FundDeployer;
    FundDeployer -- "creates fund via" --> Dispatcher;
    Dispatcher -- "deploys" --> VaultProxy;
    FundDeployer -- "deploys" --> ComptrollerProxy;
    ComptrollerProxy -- "is accessor for" --> VaultProxy;
    VaultProxy -- "delegates logic to" --> VaultLib;
```

### 1. The Persistent Layer

The Persistent Layer consists of a set of singleton contracts that are designed to be immutable and permanent. These contracts are deployed only once and are never changed. They serve as the stable foundation and anchor points for the entire system.

-   **`Dispatcher`**: The most critical contract in this layer. It is the central "kernel" of the protocol. Its responsibilities are:
    -   Acting as the single, authoritative factory for all funds (`VaultProxy` contracts).
    -   Maintaining a pointer to the `FundDeployer` contract of the current, live protocol release.
    -   Orchestrating the secure, time-locked migration of funds from an old release to a new one.

-   **`VaultProxy`**: The contract that holds a fund's assets. It is a lightweight, EIP-1822 compliant proxy whose only job is to delegate all logic to a `VaultLib` (logic) contract. Because the assets are held in the proxy, the fund's logic can be upgraded without ever needing to move the assets.

-   **Other Persistent Contracts**: This layer also includes other singleton contracts like the `ExternalPositionFactory`, which is responsible for deploying proxies for complex, non-ERC20 positions.

### 2. The Release Layer

The Release Layer contains all the logic and business rules for a specific version of the Enzyme protocol. When a new version of Enzyme is released (e.g., to add new features or integrations), a completely new set of Release Layer contracts is deployed.

-   **`FundDeployer`**: The main entry point for a specific release. It's responsible for:
    -   Creating new funds by calling the `Dispatcher`.
    -   Configuring the fund's `ComptrollerProxy` and all its associated extensions (fees, policies, etc.).
    -   Handling the logic for migrating funds *into* its release and *out of* its release during a protocol upgrade.

-   **`ComptrollerProxy` and `ComptrollerLib`**: The "brain" of a fund. The `ComptrollerProxy` is the unique `accessor` for its `VaultProxy`, meaning only it can instruct the `Vault` to perform actions. All `ComptrollerProxy` contracts in a release delegate their logic to a single, shared `ComptrollerLib` instance.

-   **Extension Contracts** (`FeeManager`, `PolicyManager`, `IntegrationManager`, etc.): These contracts handle specialized areas of logic, keeping the `ComptrollerLib` focused on core orchestration.

-   **`ValueInterpreter`**: The protocol's oracle aggregator, responsible for providing price information for all supported assets.

### How They Work Together

The `Dispatcher` acts as the bridge. It holds the address of the *current* `FundDeployer`. When a user wants to create a fund, they interact with the current `FundDeployer`, which in turn calls the `Dispatcher` to deploy the `VaultProxy`. This ensures that all funds, regardless of which release they were created on, originate from the same trusted factory.

This two-layer design provides a powerful combination of stability (the Persistent Layer) and flexibility (the Release Layer).

---

## Fund Creation Flow: A Detailed, Step-by-Step Walkthrough

The following diagram and description provide a comprehensive, in-depth view of the entire fund creation process.

```mermaid
sequenceDiagram
    participant User
    participant FundDeployer as FD
    participant ComptrollerProxy as CP
    participant ComptrollerLib as CLib
    participant Dispatcher
    participant VaultProxy as VP
    participant VaultLib
    participant Extensions as Ext

    User->>FD: createNewFund(...)

    FD->>+CP: new ComptrollerProxy(constructData, CLib address)
    CP->>+CLib: delegatecall(init(...))
    CLib-->>-CP: returns
    CP-->>-FD: returns new CP address

    FD->>+Dispatcher: deployVaultProxy(VP Lib address, owner, CP address, name)
    Dispatcher->>+VP: new VaultProxy(constructData, VP Lib address)
    VP->>+VaultLib: delegatecall(init(owner, CP address, name))
    Note right of VaultLib: storage on VP: accessor = CP address
    VaultLib-->>-VP: returns
    VP-->>-Dispatcher: returns new VP address
    Dispatcher-->>-FD: returns new VP address

    FD->>+CP: setVaultProxy(VP address)
    CP->>+CLib: delegatecall(setVaultProxy(...))
    Note right of CLib: storage on CP: vaultProxy = VP address
    CLib-->>-CP: returns
    CP-->>-FD: returns

    FD->>+Ext: setConfigForFund(CP address, VP address, feeData)
    Ext-->>-FD: returns

    FD->>+CP: activate(isMigration=false)
    CP->>+CLib: delegatecall(activate(...))
    CLib->>VP: addTrackedAsset(denomination)
    CLib->>Ext: activateForFund()
    CLib-->>-CP: returns
    CP-->>-FD: returns

    FD->>FD: initializeForVault(VP address)

```

**Initial Call:** `FundDeployer.createNewFund()`

-   **User Input:** The user provides the fund owner's address, a name and symbol for the fund's shares, the denomination asset, a shares action timelock, and encoded configuration data for fees and policies.
-   **Initial Check:** The `onlyLiveRelease` modifier ensures that this `FundDeployer` is the one currently pointed to by the `Dispatcher`.

**Step 1: `FundDeployer.__deployComptrollerProxy()`**

This private helper function is the first major action.

1.  **Encode `init` data:** The function ABI-encodes a call to the `IComptroller.init` function, passing along the `_denominationAsset` and `_sharesActionTimelock`. This packs the initialization logic for the new proxy into a `bytes` payload.
2.  **Deploy Proxy:** It deploys a new `ComptrollerProxy` contract.
3.  **Proxy Construction:** The `ComptrollerProxy`'s constructor immediately makes a `delegatecall` to the release's singleton `ComptrollerLib` address, executing the `init` function with the encoded data. This sets the fund's specific configuration (like its denomination asset) as state variables on the `ComptrollerProxy`'s storage.
4.  **Return Address:** The function returns the address of the newly deployed and initialized `ComptrollerProxy`.

**Step 2: `FundDeployer.__deployVaultProxy()`**

This private helper function calls the `Dispatcher` to create the fund's asset-holding contract.

1.  **Call `Dispatcher`:** The `FundDeployer` calls `deployVaultProxy` on the `Dispatcher` contract, passing the `_fundOwner`, the address of the `ComptrollerProxy` (as the `_vaultAccessor`), the fund name, and the release's `VaultLib` address.
2.  **`Dispatcher.deployVaultProxy()`:**
    -   **Encode `init` data:** The `Dispatcher` ABI-encodes a call to `IMigratableVault.init`, passing the `_owner`, `_vaultAccessor` (the `ComptrollerProxy`), and `_fundName`.
    -   **Deploy `VaultProxy`:** The `Dispatcher` deploys the new `VaultProxy`. This is a critical security step, as the `Dispatcher` is the single, trusted factory for all asset vaults in the protocol.
    -   **Proxy Construction & Initialization:** The `VaultProxy`'s constructor immediately makes a `delegatecall` to its `VaultLib`, executing the `init` function. This does two crucial things:
        -   It sets the `owner` of the fund.
        -   It permanently sets the `accessor` to the `ComptrollerProxy`'s address. **This is the fundamental security link of the protocol.** From this point forward, the `VaultProxy` will only accept instructions from this specific `ComptrollerProxy`.
3.  **Return Address:** The `Dispatcher` returns the address of the newly deployed `VaultProxy` to the `FundDeployer`.
4.  **Set Symbol (Optional):** If a `_fundSymbol` was provided, the `FundDeployer` makes a call to the new `VaultProxy` to set it.

**Step 3: `FundDeployer` links the proxies**

1.  **Call `setVaultProxy`:** The `FundDeployer` calls `setVaultProxy` on the `ComptrollerProxy` deployed in Step 1, passing it the address of the `VaultProxy` from Step 2. This makes the `ComptrollerProxy` aware of the vault it is designated to control.

**Step 4: `FundDeployer.__configureExtensions()`**

This private helper configures all the extensions for the new fund.

1.  **Loop Through Extensions:** The function makes a series of `setConfigForFund` calls to the release's singleton extension contracts (`FeeManager`, `PolicyManager`, `IntegrationManager`, `ExternalPositionManager`).
2.  **`setConfigForFund` on each Extension:**
    -   The extension receives the addresses of the new `ComptrollerProxy` and `VaultProxy`.
    -   It calls `__setValidatedVaultProxy` to cache this link, ensuring it will only accept calls from this `ComptrollerProxy` when acting on behalf of this `VaultProxy`.
    -   It decodes the specific configuration data (e.g., the `_feeManagerConfigData`) and sets up the fund's specific settings within that extension's storage.

**Step 5: `FundDeployer` activates the fund**

1.  **Call `activate`:** The `FundDeployer` calls `activate` on the `ComptrollerProxy`.
2.  **`ComptrollerLib.activate()`:**
    -   The `activate` function on the `ComptrollerLib` is executed via `delegatecall`.
    -   It instructs the `VaultProxy` to add the `denominationAsset` to its list of tracked assets.
    -   It then calls `activateForFund` on the `FeeManager` and `PolicyManager`, allowing them to perform any final setup now that the fund is fully configured.

**Step 6: `FundDeployer` initializes the protocol fee tracker**

1.  **Call `initializeForVault`:** The `FundDeployer` calls `initializeForVault` on the release's `ProtocolFeeTracker`, passing in the new `VaultProxy` address. This registers the fund for protocol-level fee collection.

**Final State:** At the end of this process, a fully configured and secure fund is live. The `VaultProxy` holds the assets, the `ComptrollerProxy` holds the configuration and logic pointers, and the two are immutably linked, ensuring that only the designated logic can instruct the vault to perform actions.

---

## Fund Lifecycle: Core Interactions

### 1. Buying Shares (Investment)

An investor buys shares by calling `buyShares` on the fund's `ComptrollerProxy`.

```mermaid
sequenceDiagram
    participant Investor
    participant ComptrollerProxy
    participant FeeManager
    participant VaultProxy

    Investor->>ComptrollerProxy: buyShares(...)
    ComptrollerProxy->>FeeManager: invokeHook(PreBuyShares)
    ComptrollerProxy->>VaultProxy: payProtocolFee()
    Investor-->>VaultProxy: ERC20.transferFrom()
    ComptrollerProxy->>VaultProxy: mintShares()
    ComptrollerProxy->>FeeManager: invokeHook(PostBuyShares)
```

1.  **`ComptrollerLib`**: The `buyShares` logic begins.
2.  **GAV Calculation**: The `ComptrollerLib` calculates the fund's current Gross Asset Value (GAV).
3.  **Pre-Buy-Shares Hooks**: The `ComptrollerLib` calls `invokeHook` on the `FeeManager`, triggering any entrance fees.
4.  **Protocol Fee**: Any outstanding protocol fees are paid.
5.  **Asset Transfer**: The investor's investment assets (e.g., USDC) are transferred into the `VaultProxy`.
6.  **Share Calculation**: The number of shares to issue is calculated based on the GAV and the amount of assets received.
7.  **`VaultProxy`**: The `ComptrollerLib` instructs the `VaultProxy` to `mint` the new shares to the investor.
8.  **Post-Buy-Shares Hooks**: The `ComptrollerLib` calls hooks on the `FeeManager` and `PolicyManager`.

### 2. Performing an Action (e.g., a Trade)

A fund manager performs a trade by calling `callOnExtension` on the `ComptrollerProxy`.

```mermaid
sequenceDiagram
    participant Manager
    participant ComptrollerProxy
    participant IntegrationManager
    participant PolicyManager
    participant UniswapAdapter
    participant Uniswap

    Manager->>ComptrollerProxy: callOnExtension(IntegrationManager, ...)
    ComptrollerProxy->>IntegrationManager: receiveCallFromComptroller(...)
    IntegrationManager->>UniswapAdapter: approve()
    IntegrationManager->>UniswapAdapter: trade()
    UniswapAdapter->>Uniswap: swapExactTokensForTokens()
    IntegrationManager->>PolicyManager: validatePolicies()
```

1.  **`ComptrollerLib`**: The call is routed to the `IntegrationManager`.
2.  **`IntegrationManager`**: The `IntegrationManager` parses the arguments.
3.  **Pre-Processing**: The `IntegrationManager` records balances and approves the adapter to spend assets.
4.  **External Call**: The `IntegrationManager` calls the adapter, which executes the trade on Uniswap.
5.  **Post-Processing**: The `IntegrationManager` checks balances, slippage, and revokes approvals.
6.  **Policy Validation**: The `IntegrationManager` calls the `PolicyManager` to ensure compliance.

### 3. Redeeming Shares

An investor redeems shares by calling one of the redeem functions on the `ComptrollerProxy`.

---

## Protocol Upgrade Flow

```mermaid
sequenceDiagram
    participant Owner
    participant Manager
    participant NewFundDeployer
    participant Dispatcher
    participant VaultProxy

    Owner->>Dispatcher: setCurrentFundDeployer(NewFundDeployer)
    Manager->>NewFundDeployer: createMigrationRequest()
    NewFundDeployer->>Dispatcher: signalMigration()
    Note right of Dispatcher: Timelock period begins
    Manager->>Dispatcher: executeMigration()
    Dispatcher->>VaultProxy: setVaultLib(...)
    Dispatcher->>VaultProxy: setAccessor(...)
```

1.  **Deploy New Release**: A new set of Release Layer contracts is deployed.
2.  **Upgrade `Dispatcher`**: The protocol owner calls `setCurrentFundDeployer` on the `Dispatcher`, pointing it to the `FundDeployer` of the new release.
3.  **Signal Migration**: The manager of an existing fund calls `createMigrationRequest` on the *new* `FundDeployer`. The new `FundDeployer` deploys a new `ComptrollerProxy` and then calls `signalMigration` on the `Dispatcher`, which creates a time-locked `MigrationRequest`.
4.  **Migration Timelock**: A waiting period begins.
5.  **Execute Migration**: After the timelock expires, `executeMigration` is called on the `Dispatcher`. The `Dispatcher` then upgrades the fund's `VaultProxy` to point to the new `VaultLib` and the new `ComptrollerProxy`.
