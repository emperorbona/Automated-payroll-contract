# 📟 Automated Payroll Smart Contract

This project implements a decentralized **Automated Payroll System** using **Solidity**, **Chainlink Automation**, and **Foundry**. The contract enables employers to register employees, fund the payroll, and automatically pay salaries at regular intervals without manual intervention.

---

## 📆 Features

* ✅ **Employee Management**

  * Add new employees with name, address, and salary.
  * Remove employees dynamically.

* ✅ **Automation with Chainlink Keepers**

  * Periodically checks if salary payments are due.
  * Automatically disburses salaries to employees based on defined intervals.

* ✅ **Secure and Configurable**

  * Owner-only administrative actions.
  * Configurable minimum funding amount and payment interval.

* ✅ **Tested with Foundry**

  * Unit tests for all core functionalities.
  * Deploy and automate locally or on testnets using Chainlink Automation.

---

## 📁 Project Structure

```
.
├── contracts
│   └── Payroll.sol
├── script
│   ├── Deploy.s.sol
│   ├── CreateAndFundSub.s.sol
│   └── AddConsumer.s.sol
├── test
│   └── Payroll.t.sol
├── helperConfig
│   └── HelperConfig.s.sol
├── foundry.toml
└── README.md
```

---

## 🚀 Deployment

Deploy the contract using Foundry scripts:

```bash
forge script script/Deploy.s.sol --broadcast --rpc-url <YOUR_RPC_URL>
```

---

## ⚙️ Chainlink Automation Setup

1. **Create and Fund a Subscription:**

```bash
forge script script/CreateAndFundSub.s.sol --broadcast --rpc-url <YOUR_RPC_URL>
```

2. **Add Consumer to Subscription:**

```bash
forge script script/AddConsumer.s.sol --broadcast --rpc-url <YOUR_RPC_URL>
```

3. **Register the Contract as a Keeper:**

Go to [Chainlink Automation App](https://automation.chain.link/) and register your deployed contract with the subscription ID.

---

## 🔎 Key Functions

### Admin (Owner Only)

* `addEmployee(string name, address wallet, uint256 salary)`
* `removeEmployee(string name)`
* `FundPayroll()`
* `withdrawFromPayroll()`

### Chainlink Keeper Functions

* `checkUpkeep(bytes calldata)`
* `performUpkeep(bytes calldata)`

### View Functions

* `getEmployees(uint index)`
* `getNameToEmployeeData(string name)`
* `getLastTimeStamp()`
* `getMinimumAmountToFundContract()`
* `getOwner()`
* `getEmployeeCount()`

---

## 💪 Testing

Run tests using Foundry:

```bash
forge test
```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙌 Acknowledgements

* [Chainlink Documentation](https://docs.chain.link)
* [Foundry Book](https://book.getfoundry.sh/)
