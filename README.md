# ovote  [![Circuits](https://github.com/aragon/ovote/workflows/Circuits/badge.svg)](https://github.com/aragon/ovote/actions/workflows/circuits.yml?query=workflow%3ACircuits) [![Contracts](https://github.com/aragon/ovote/workflows/Contracts/badge.svg)](https://github.com/aragon/ovote/actions/workflows/contracts.yml?query=workflow%3AContracts) [![Clientlib](https://github.com/aragon/ovote/workflows/Clientlib/badge.svg)](https://github.com/aragon/ovote/actions/workflows/clientlib.yml?query=workflow%3AClientlib)

*Research project*

OVOTE: Offchain Voting with Onchain Trustless Execution.

This repo contains the circuits, contracts & web client library for the OVOTE, compatible with the [ovote-node](https://github.com/aragon/ovote-node). All code is in early stages.

More details on the OVOTE circuits and contracts design can be found at the [OVOTE document](https://github.com/aragon/research/blob/main/ovote/ovote-draft.pdf).


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

