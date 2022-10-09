// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract BlockHashRegistry {
    mapping(uint256 => bytes32) public hashes;

    constructor() {
        // Hard-coding the first post-merge block.
        // https://etherscan.io/block/15537393
        hashes[15537393] = 0x55b11b918355b1ef9c5db810302ebad0bf2544255b530cdce90674d5887bb286;
        hashes[block.number - 1] = blockhash(block.number - 1);
    }

    function poke() public {
        poke(block.number - 1);
    }

    function poke(uint256 blockNum) public {
        bytes32 pokeHash = blockhash(blockNum);
        hashes[blockNum] = pokeHash;
    }

    // TODO(sina) the params to this fn should map to the verifier's input
    function prove() public {
        // TODO(sina) get stuff;
        hashes[0] = bytes32(0);
    }
}
