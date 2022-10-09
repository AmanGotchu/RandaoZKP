pragma circom 2.0.2;

include "../circom-pairing/node_modules/circomlib/circuits/bitify.circom";
include "../circom-pairing/node_modules/circomlib/circuits/comparators.circom";
include "../circom-pairing/node_modules/circomlib/circuits/multiplexer.circom";
include "../circom-pairing/circuits/bn254/groth16.circom";

include "./utils/keccak.circom";
include "./utils/rlp.circom";
include "./utils/mpt.circom";

template BabyBlockChecker() {
    // this was created by combining Yi Sun's RLP verification proof in
    // https://github.com/yi-sun/zk-attestor/blob/f4f4b2268f7cf8a0e5ac7f2b5df06a61859f18ca/circuits/rlp.circom
    // with nawlin's recursive zk snark project Isokratia example code in
    // https://github.com/nalinbhardwaj/circom-pairing/blob/082e7705a8a384e7c7568944fa216d3eb8d863ed/scripts/recursion/recursion.circom#L5

    // bn254 curve property
    var k2 = 6;

    // Input, RLP representation of the block.
    signal input blockRlpHexs[1112]; // 1112 bytes of RLP encoding
    // Outputs.
    signal output blockHashHexs[64];
    signal output parentHash[64];

    // RLP stuff
    component rlp = RlpArrayCheck(1112, 16, 4,
        	      [64, 64, 40, 64, 64, 64, 512,  0, 0, 0, 0, 0,  0, 64, 16,  0],
				  [64, 64, 40, 64, 64, 64, 512, 14, 6, 8, 8, 8, 64, 64, 18, 10]);
    for (var idx = 0; idx < 1112; idx++) {
    	rlp.in[idx] <== blockRlpHexs[idx];
    }
    var blockRlpHexLen = rlp.totalRlpHexLen;
    component pad = ReorderPad101Hex(1016, 1112, 1360, 13);
    pad.inLen <== blockRlpHexLen;
    for (var idx = 0; idx < 1112; idx++) {
        pad.in[idx] <== blockRlpHexs[idx];
    }
    // if leq.out == 1, use 4 rounds, else use 5 rounds
    component leq = LessEqThan(13);
    leq.in[0] <== blockRlpHexLen + 1;
    // 4 * blockSize = 1088
    leq.in[1] <== 1088;

    // Hash the RLP rep
    var blockSizeHex = 136 * 2;
    component keccak = Keccak256Hex(5);
    for (var idx = 0; idx < 5 * blockSizeHex; idx++) {
        keccak.inPaddedHex[idx] <== pad.out[idx];
    }
    keccak.rounds <== 5 - leq.out;
    for (var idx = 0; idx < 32; idx++) {
        blockHashHexs[2 * idx] <== keccak.out[2 * idx + 1];
	    blockHashHexs[2 * idx + 1] <== keccak.out[2 * idx];
    }
    for (var idx = 0; idx < 64; idx++) {
        parentHash[idx] <== rlp.fields[0][idx];
    }
}

component main = BabyBlockChecker();
