# EthBogota Hackathon October 2022 - on chain verification of block hashes

## Motivation
On-chain randomness in ethereum is difficult because of potential manipulation via inclusion/exclusion by proposers and the transparent nature of the blockchain data and algorithms.  Many projects rely on Chainlink’s VRF as an external trusted source of randomness, but it can be time consuming to integrate and introduces external trust assumptions.

We propose bringing the beacon chain’s existing RanDAO RNG values on chain.  In future work, our contract will provide numbers uniformly distributed in the interval (0, 1) based on commitments to *future* RanDAO values.  For this particular application, only one value/block hash needs to be committed per epoch.

Recursive zk-SNARKs can provide succinct verification that the block header/RanDAO values attested to are correct by confirming they generate a sequence (of the expected length) of block headers up to some known recent block hash.

This repository includes circom contracts for verifying block headers. Our simple demo circuit outputs the block hash for
a given block header,.  We have work in progress to generate recursive zk-SNARKs for posting arbitrarily old block hashes in constant on chain compute/storage.

## Circom Circuits
Consistent with block hash calcaultion, our circuits expect the block header [RLP](https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/) to be encoded as a sequence of `1112` hex values, which are then hashed and then validated against the next block header's `parentHash` field.

Our approach benefits from the fact that the most recent 256 block hashes are available natively inside the ethereum L1
execution environment, allowing some recent hash to be committed/confirmed to the state history without additional verification.

Our WIP recursive zk-SNARKs can then choose a given historical block hash and generate a proof linking it to the known recent hash,
by validating the entire history of block hashes in between (via the parentHash field present in each block header).

Since we are only attesting the RanDAO values and black hashes, the remainder block header values can be treated as private input (part of the witness) for our circuit.  This will help keep proof size (and on-chain state) small. 

We are fortunate that RLP, SHA256 and one curve pairing have open source implementations in circom.

## Applications
An immediate application is re-using the RanDAO RNG seed generation from the beacon chain for native RNG in the execution environment without
off chain integrations.  This can be done by having smart contracts commit to future values of RanDAO (possibly with a Verifiable Delay Function on top),
which is effectively ungameable despite the known "k-bits" biasability of the beacon chain's implementation of RanDAO.

## Instructions

To use our code to generate and verify block hashes, you will have to

(1) Copy `.env_` into `.env` and set the environment variable `RPC_API_KEY=""` and `RPC_URL` to your preferred RPC provider. We have tested our scripts with Infura.

(2) We assume that the [universal trusted setup powers of tau file](https://github.com/weijiekoh/perpetualpowersoftau) has been downloaded and mounted/placed in
`/powers-of-tau/powersOfTau28_hez_final_25.ptau`. this is configurable in `circuits/build_single_block.sh`, which compiles the circom circuits and generates/validates an example proof for block `15705750`.

(3) optional - use our provided [Dockerfile](Dockerfile) to run the code with necessary requirements.  It may be helpful to create a dedicated volume with the powers of tau file and mount it onto the runtime.

## Block Header Processing
Block headers are preprocessed into an RLP encoded format prior to hashing.  We provide a script for generating blockheaders from an RPC provider in [scripts/getBlockHeaders.ts](scripts/getBlockHeaders.ts).

## TODO

Complete the recursive zk-SNARKs so that arbitrary block hashes can be added onto the smart contract mapping.  We expected circuit compilation times in excess of 24 hours, which prevented their readiness in time for the end of this hackathon.

## Related Projects

[Relic Protocol](https://relicprotocol.com/) is very similar in intention and objective, but targets a much more general use case.  We think focusing on on-chain RNG provides a concrete, useful application that will be faster to implement.  Our project is to build “bottom up” vs their “top down” roadmap.

Yi Sun has some prototype code for [attesting to more granular historical account state](https://github.com/yi-sun/zk-attestor), which is quite similar in spirit to our project, but for very different use cases.  We thank Yi for tremendously useful related work.

https://github.com/amiller/ethereum-blockhashes implements a naive record of historical blockhashes.

## Additional Technical Notes

### RanDAO
The beacon chain uses a multiparty commit-reveal [protocol called RanDAO](https://eth2.incessant.ink/book/06__building-blocks/02__randomness.html#wait-what-is-randomness) within each epoch (32 blocks/slots, ~7.4 minutes) to reshuffle proposers.  For every block, the proposer also signs a message which commits a contributution to the current RNG seed state, which is then revealed at the start of the next epoch.

Because of the commit-reveal scheme, one valid random number is generated each epoch.  We do not think the block level mixed values cannot be used (but are not certain of this).

### Block Headers

We are fortunate that RanDAO values are present in the block header, so our circuit only has to prove that the block header values hash to the known block hashes.  There are no merkle/patricia proofs against state/transaction tries.  It is straightforward to naively recurse from block to block, because the previous block hash is present in the current block’s header.  After PoS, the PoW `mixHash` header value has been replaced with the current `RanDAO` value.

Our (wip) recursive zk-SNARKs check that our claimed block header values hash (recursively) up until some recent known valid block hash that is available on chain.  If we are able to provide a chain of block headers that satisfy this property, the hardness of SHA256 justifies our claimed values are the true historical header values.
