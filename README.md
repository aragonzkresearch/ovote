# ovote  [![Circuits](https://github.com/aragonzkresearch/ovote/workflows/Circuits/badge.svg)](https://github.com/aragonzkresearch/ovote/actions/workflows/circuits.yml?query=workflow%3ACircuits) [![Contracts](https://github.com/aragonzkresearch/ovote/workflows/Contracts/badge.svg)](https://github.com/aragonzkresearch/ovote/actions/workflows/contracts.yml?query=workflow%3AContracts)

*Research project*

## OVOTE: Offchain Voting with Onchain Trustless Execution

This repo contains the OVOTE circuits and contracts, compatible with the [ovote-node](https://github.com/aragonzkresearch/ovote-node) and [ovote-clientlib](https://github.com/aragonzkresearch/ovote-node). All code is in early stages.

More details on the OVOTE circuits and contracts design can be found at the [OVOTE document](https://github.com/aragonzkresearch/research/blob/main/drafts/ovote.pdf).

## OAV: Onchain Anonymous Voting
Reusing the same census created for OVOTE, users can vote onchain anonymously.

In OAV, voters generate a zkSNARK proof in their browsers proving that they know the private key which public key is in the Census MerkleTree and that they generated a valid signature over the vote value with that key.

## Test

- Circuits
   - Needs installed: [circom](https://github.com/iden3/circom), [nodejs](https://nodejs.org) (version: >16)
   - Install the dependencies: `npm install`
   - Run the tests: `npm run test`
- Contracts
   - Needs installed: [foundry](https://github.com/gakonst/foundry)
   - Run the tests: `forge test`
