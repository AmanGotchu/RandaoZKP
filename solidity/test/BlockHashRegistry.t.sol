// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BlockHashRegistry.sol";
import "./VerifierTesterHelper.t.sol";

contract BlockHashRegistryTest is VerifierTesterHelper, Test {
    using stdStorage for StdStorage;

    BlockHashRegistry public registry;

    uint256 constant HARDCODED_BLOCKNUM = 15705750;
    bytes32 constant HARDCODED_BLOCKHASH =
        0x42769f4ff05e362ad18c12844d7c06bac8df9cbca5cbfa1b9e1645e4d624e6c0;

    function setUp() public {
        registry = new BlockHashRegistry();
        stdstore
            .target(address(registry))
            .sig("numToHash(uint256)")
            .with_key(HARDCODED_BLOCKNUM)
            .checked_write(HARDCODED_BLOCKHASH);
    }

    function testProve() public {
        uint256[198] memory input = [
            uint256(4),
            2,
            7,
            6,
            9,
            15,
            4,
            15,
            15,
            0,
            5,
            14,
            3,
            6,
            2,
            10,
            13,
            1,
            8,
            12,
            1,
            2,
            8,
            4,
            4,
            13,
            7,
            12,
            0,
            6,
            11,
            10,
            12,
            8,
            13,
            15,
            9,
            12,
            11,
            12,
            10,
            5,
            12,
            11,
            15,
            10,
            1,
            11,
            9,
            14,
            1,
            6,
            4,
            5,
            14,
            4,
            13,
            6,
            2,
            4,
            14,
            6,
            12,
            0,
            4,
            4,
            14,
            13,
            7,
            14,
            4,
            13,
            14,
            9,
            3,
            12,
            5,
            11,
            2,
            13,
            4,
            5,
            13,
            2,
            4,
            12,
            2,
            15,
            11,
            12,
            13,
            14,
            10,
            14,
            11,
            0,
            9,
            4,
            14,
            4,
            13,
            2,
            6,
            1,
            5,
            10,
            9,
            1,
            0,
            10,
            0,
            15,
            3,
            14,
            6,
            13,
            12,
            14,
            7,
            10,
            15,
            14,
            1,
            6,
            5,
            13,
            11,
            5,
            14,
            15,
            10,
            6,
            9,
            6,
            1,
            15,
            11,
            14,
            15,
            5,
            11,
            4,
            7,
            12,
            7,
            12,
            14,
            0,
            9,
            5,
            13,
            3,
            7,
            8,
            0,
            12,
            12,
            0,
            1,
            7,
            5,
            5,
            5,
            7,
            5,
            15,
            13,
            8,
            2,
            3,
            11,
            4,
            4,
            12,
            9,
            6,
            13,
            0,
            0,
            10,
            10,
            7,
            0,
            3,
            15,
            14,
            0,
            1,
            10,
            9,
            9,
            10,
            7,
            13,
            7,
            2,
            13,
            8
        ];
        registry.prove(
            [
                5013632651693382502147302031468187780022098352068803419175672899085027218076,
                14462875524615589039913740242922996488895401081654630234283626167085021417051
            ],
            [
                [
                    1612705106486575990293420540103215011641373145409525897339473420593035431897,
                    19642208470577890678008596478971998067721776828357418585449732314716478865738
                ],
                [
                    20267688270971444139506694209878978084792244579614526841233011682365863792624,
                    3657207772374573380432856442225710598406143755615933272485132311562341109251
                ]
            ],
            [
                9863678792786527269830076556444517628046273465850059261189210888234296705256,
                479476218186049415710902367667905684957392883242639393539333839332398602294
            ],
            input
        );
    }
}
