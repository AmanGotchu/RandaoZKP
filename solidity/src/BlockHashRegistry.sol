// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../singleBlockHeader_verifier.sol";

error InvalidProof();
error InvalidAnchorHash(bytes32 anchorHash);

contract BlockHashRegistry is Verifier {
    mapping(uint256 => bytes32) public numToHash;
    mapping(uint256 => bytes32) public numToRandMix;

    constructor() {
        poke();
    }

    function setEntry(
        uint256 blockNum,
        bytes32 blockHash,
        bytes32 randMix
    ) internal {
        numToHash[blockNum] = blockHash;
        numToRandMix[blockNum] = randMix;
    }

    function poke() public {
        setEntry(
            block.number - 1,
            blockhash(block.number - 1),
            bytes32(block.difficulty)
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
        bytes32 anchorHash;
        for (; i < 64; i++) {
            anchorHash <<= 4;
            anchorHash |= bytes32(input[i]);
        }
        // Next 64 are parentHash.
        bytes32 parentHash;
        for (; i < 128; i++) {
            parentHash <<= 4;
            parentHash |= bytes32(input[i]);
        }
        // Next 6 are parentBlockNum.
        bytes32 parentBlockNumAccumulator;
        for (; i < 134; i++) {
            parentBlockNumAccumulator <<= 4;
            parentBlockNumAccumulator |= bytes32(input[i]);
        }
        uint256 parentBlockNum = uint256(parentBlockNumAccumulator);
        // Next 64 are mixHash.
        bytes32 parentMixHash;
        for (; i < 198; i++) {
            parentMixHash <<= 4;
            parentMixHash |= bytes32(input[i]);
        }
        // Set the new hash.
        if (numToHash[parentBlockNum + 1] != anchorHash) {
            revert InvalidAnchorHash(anchorHash);
        }
        setEntry(parentBlockNum, parentHash, parentMixHash);
    }
}
