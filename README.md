# RIF Enveloping - V2

A secure sponsored-transaction system to enable users to pay fees using ERC-20 tokens.

[![CircleCI](https://circleci.com/gh/rsksmart/enveloping/tree/master.svg?style=shield)](https://circleci.com/gh/rsksmart/enveloping/tree/master)
## Description

The first version of Enveloping was based on the [Gas Station Network (GSN) project](https://github.com/opengsn/gsn). GSN is a decentralized system that improves dApp usability without sacrificing security. In a nutshell, GSN abstracts away gas (used to pay transaction fees) to minimize onboarding and UX friction for dApps. With GSN, "gasless clients" can interact with smart contracts paying for gas with tokens instead of native-currency.

RIF Enveloping V2 is a redesign of GSN. It reduces gas costs and simplifies contract interaction.

It achieves this by:

- Securely deploying counterfactual Smart Wallet proxies for each user account: this eliminates the need for relying on _msgSender() and _msgData() functions, making existing and future contracts compatible with RIF Enveloping without any modification.
- Allowing Relay providers to receive tokens in a worker address under their control to later on decide what to do with funds.
- Reducing gas costs by optimizing the existing GSN architecture.

Our main objective is to provide the RSK ecosystem with the means to enable blockchain applications and end-users (wallet-apps) to pay for transaction fees using tokens (e.g. RIF tokens), and thereby remove the need to acquire RBTC in advance.

It is important to recall that  - as a security measure - the version 1 contracts deployed on Mainnet have limits on the staked amounts to operate, these limits were removed in version 2.

## Technical Documentation

The following technical content are available:

- Enveloping architecture [docs/enveloping_architecture](docs/enveloping_architecture.md)
- Installing basic requirements [docs/basic_requirements](docs/basic_requirements.md)
- Launching enveloping [docs/launching_enveloping](docs/launching_enveloping.md)
- Development guide [docs/development_guide](docs/development_guide.md)
- Integration guide [docs/integration_guide](docs/integration_guide.md)
- RIF Enveloping gas costs [docs/overhead_tx_costs](docs/overhead_tx_costs.md)


## Testnet Contracts - V2

| Contract          | Address                                    |
|-------------------|--------------------------------------------|
| [Penalizer]       | TBD |
| [RelayHub]        | TBD |
| [SmartWallet]     | TBD |
| [SmartWalletFactory]    | TBD |
| [CustomSmartWallet]     | TBD |
| [CustomSmartWalletFactory]    | TBD |
| [DeployVerifier] | TBD |
| [RelayVerifier]  | TBD |
| [TestRecipient]   | TBD |

[Penalizer]:(https://explorer.testnet.rsk.co/address/)
[RelayHub]:(https://explorer.testnet.rsk.co/address/)
[SmartWallet]:(https://explorer.testnet.rsk.co/address/)
[SmartWalletFactory]:(https://explorer.testnet.rsk.co/address/)
[CustomSmartWallet]:(https://explorer.testnet.rsk.co/address/)
[CustomSmartWalletFactory]:(https://explorer.testnet.rsk.co/address/)
[DeployVerifier]:(https://explorer.testnet.rsk.co/address/)
[RelayVerifier]:(https://explorer.testnet.rsk.co/address/)
[TestRecipient]:(https://explorer.testnet.rsk.co/address/)

## Changelog

### V2

* In V2 the Relay Hub contract doesn't receive payments, the payment for the service (in tokens) is paid directly to the worker relaying the transaction on behalf of the user.

* Paymaster verifications are now done off-chain to optimize gas costs, thus the paymasters are now called Verifiers and they are not part of the on-chain relay flow nor they handle payments at all.

* Gas cost optimization

* Security issues fixed.
