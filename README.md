# zkmultisig  [![Circuits](https://github.com/aragon/zkmultisig/workflows/Circuits/badge.svg)](https://github.com/aragon/zkmultisig/actions/workflows/circuits.yml?query=workflow%3ACircuits) [![Contracts](https://github.com/aragon/zkmultisig/workflows/Contracts/badge.svg)](https://github.com/aragon/zkmultisig/actions/workflows/contracts.yml?query=workflow%3AContracts) [![Clientlib](https://github.com/aragon/zkmultisig/workflows/Clientlib/badge.svg)](https://github.com/aragon/zkmultisig/actions/workflows/clientlib.yml?query=workflow%3AClientlib)

*Research project*

zkMultisig: scalable offchain voting with onchain trustless binding results.

This repo contains the circuits, contracts & web client library for the zkMultisig, compatible with the [zkmultisig-node](https://github.com/aragon/zkmultisig-node). All code is in early stages.


## Test

- Circuits
   - Needs installed: [circom](https://github.com/iden3/circom), [nodejs](https://nodejs.org) (version: >16)
   - Install the dependencies: `npm install`
   - Run the tests: `npm run test`
- Contracts
   - Needs installed: [foundry](https://github.com/gakonst/foundry)
   - Run the tests: `forge test`
- Clientlib
   - Needs installed: [nodejs](https://nodejs.org) (version: >16)
   - Install the dependencies: `npm install`
   - Run the tests: `npm run test`
