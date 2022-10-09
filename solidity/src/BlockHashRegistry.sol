// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../singleBlockHeader_verifier.sol";

error InvalidProof();
error InvalidBlockHash(bytes32 blockHash);
error LinksUnavailable(bytes32 blockHash, uint256 blockNum);

contract BlockHashRegistry is Verifier {
    mapping(uint256 => bytes32) public numToHash;
    mapping(uint256 => bytes32) public numToParentHash;
    mapping(uint256 => bytes32) public numToRandMix;

    constructor() {
        poke();
    }

    function setEntry(
        uint256 blockNum,
        bytes32 blockHash,
        bytes32 parentHash
    ) internal {
        numToHash[blockNum] = blockHash;
        numToParentHash[blockNum] = parentHash;
    }

    function sentEntryRandao(
        uint256 blockNum,
        bytes32 blockHash,
        bytes32 parentHash,
        bytes32 randMix
    ) internal {
        numToHash[blockNum] = blockHash;
        numToParentHash[blockNum] = parentHash;
        numToRandMix[blockNum] = randMix;
    }

    function poke() public {
        setEntry(
            block.number - 1,
            blockhash(block.number - 1),
            blockhash(block.number - 2)
        );
    }

    function prove(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[198] memory input
    ) public {
        if (!verifyProof(a, b, c, input)) {
            revert InvalidProof();
        }
        // Parse what we care about from the input.
        uint256 i = 0;
        // First 64 entries are anchorHash.
        bytes32 blockHash;
        for (; i < 64; i++) {
            blockHash <<= 4;
            blockHash |= bytes32(input[i]);
        }
        // Next 64 are parentHash.
        bytes32 parentHash;
        for (; i < 128; i++) {
            parentHash <<= 4;
            parentHash |= bytes32(input[i]);
        }
        // Next 6 are blockNum.
        bytes32 blockNumAccumulator;
        for (; i < 134; i++) {
            blockNumAccumulator <<= 4;
            blockNumAccumulator |= bytes32(input[i]);
        }
        uint256 blockNum = uint256(blockNumAccumulator);
        // Next 64 are mixHash.
        bytes32 blockMixHash;
        for (; i < 198; i++) {
            blockMixHash <<= 4;
            blockMixHash |= bytes32(input[i]);
        }

        // Check current block
        if (numToHash[blockNum] != 0) {
            if (numToHash[blockNum] == blockHash) {
                sentEntryRandao(blockNum, blockHash, parentHash, blockMixHash);
                return;
            }

            revert InvalidBlockHash(blockHash);
        }

        // Check parent block.
        if (numToHash[blockNum - 1] != 0) {
            if (numToHash[blockNum - 1] == parentHash) {
                sentEntryRandao(blockNum, blockHash, parentHash, blockMixHash);
                return;
            }

            revert InvalidBlockHash(blockHash);
        }

        // Check child block.
        if (numToParentHash[blockNum + 1] != 0) {
            if (numToParentHash[blockNum + 1] == blockHash) {
                sentEntryRandao(blockNum, blockHash, parentHash, blockMixHash);
                return;
            }

            revert InvalidBlockHash(blockHash);
        }

        revert LinksUnavailable(blockHash, blockNum);
    }
}
