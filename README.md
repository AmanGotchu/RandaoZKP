#Instructions

This repository includes circom contracts for verifying block headers. Our simple demo simply recreates the block hash for
a given block header, which can be generated in the expected RLP encoded format by using the file `scripts/getBlockHeaders.ts`.

Our circuits expect the block header RLP to be encoded as a sequence of 1112 hex values, which are then hashed and then validated
against the next block header's `parentHash` field.

Our smart contract uses the fact that the most recent 256 block hashes are available natively inside the ethereum L1
execution environment, allowing some recent hash to be committed/confirmed to the state history without additional verification.
Our smart contract/zk-SNARKs can then choose a given historical block hash and generate a proof linking it to the known recent hash,
by validating the entire history of block hashes in between (via the parentHash field present in each block header).

To use our files, you will have to

(1) Set the environment variable RPC_API_KEY="" to your api providers api key. We have tested this repo with Infura.

(2) We assume that the universal trusted setup powers of tau file has been downloaded and mounted/placed in
`/powers-of-tau/powersOfTau28_hez_final_25.ptau`. this is configurable in `circuits/build_single_block.sh`.
