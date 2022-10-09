// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../singleBlockHeader_verifier.sol";

error InvalidProof();
error InvalidAnchorHash(bytes32 anchorHash);

contract BlockHashRegistry is Verifier {
    mapping(uint256 => bytes32) public numToHash;
    mapping(bytes32 => uint256) public hashToNum;

    constructor() {
        // Hard-coding the first post-merge block.
        // https://etherscan.io/block/15537393
        setEntry(15537393, 0x55b11b918355b1ef9c5db810302ebad0bf2544255b530cdce90674d5887bb286);
        poke(block.number - 1);
        poke(block.number - 256);
    }

    function setEntry(uint256 blockNum, bytes32 blockHash) internal {
        assert(blockHash != bytes32(0));
        numToHash[blockNum] = blockHash;
        hashToNum[blockHash] = blockNum;
    }

    function poke() public {
        poke(block.number - 1);
    }

    function poke(uint256 blockNum) public {
        setEntry(blockNum, blockhash(blockNum));
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
        // Next 6 are blockNumber.
        bytes32 blockNum;
        for (; i < 134; i++) {
            blockNum <<= 4;
            blockNum |= bytes32(input[i]);
        }
        // Next 64 are mixHash.
        bytes32 mixHash;
        for (; i < 198; i++) {
            mixHash <<= 4;
            mixHash |= bytes32(input[i]);
        }
        // Set the new hash.
        uint256 provenBlockNum = hashToNum[anchorHash] - 1;
        if (provenBlockNum == 0) {
            revert InvalidAnchorHash(anchorHash);
        }
        setEntry(provenBlockNum, parentHash);
    }
}
