pragma circom 2.0.2;

include "../circom-pairing/node_modules/circomlib/circuits/bitify.circom";
include "../circom-pairing/node_modules/circomlib/circuits/comparators.circom";
include "../circom-pairing/node_modules/circomlib/circuits/multiplexer.circom";
include "../circom-pairing/circuits/bn254/groth16.circom";

include "./utils/keccak.circom";
include "./utils/rlp.circom";
include "./utils/mpt.circom";

// State, TX, Receipts, Number, Parent hash, Mix hash (block randomness)
template SingleEthBlockHashHex(publicInputCount) {
    // this was stolen from Yi Sun's RLP verification proof in
    // https://github.com/yi-sun/zk-attestor/blob/f4f4b2268f7cf8a0e5ac7f2b5df06a61859f18ca/circuits/rlp.circom
    signal input blockRlpHexs[1112]; // 1112 bytes of RLP encoding

    // Outputs

    // these are 32 bytes, but we work with their 64 hex representation.
    // i have no idea why though.
    signal output currentHash[64];
    signal output parentHash[64];
    signal output blockNumber[6];
    signal output mixHash[64];

    // Decoding RLP input
    for (var idx = 0; idx < 1112; idx++) {
        log(blockRlpHexs[idx]);
    }

    // thank you Yi
    component rlp = RlpArrayCheck(1112, 16, 4,
                [64, 64, 40, 64, 64, 64, 512,  0, 0, 0, 0, 0,  0, 64, 16,  0],
				[64, 64, 40, 64, 64, 64, 512, 14, 6, 8, 8, 8, 64, 64, 18, 10]);
    for (var idx = 0; idx < 1112; idx++) {
    	rlp.in[idx] <== blockRlpHexs[idx];
    }  // helper for grabbing specific key/values from the RLP

    var blockRlpHexLen = rlp.totalRlpHexLen;
    component pad = ReorderPad101Hex(1016, 1112, 1360, 13);
    pad.inLen <== blockRlpHexLen;  // no idea
    for (var idx = 0; idx < 1112; idx++) {
        pad.in[idx] <== blockRlpHexs[idx];
    }

    // not sure whats going on here

    // if leq.out == 1, use 4 rounds, else use 5 rounds
    component leq = LessEqThan(13);
    leq.in[0] <== blockRlpHexLen + 1;
    // 4 * blockSize = 1088
    leq.in[1] <== 1088;
    
    var blockSizeHex = 136 * 2;
    component keccak = Keccak256Hex(5);
    for (var idx = 0; idx < 5 * blockSizeHex; idx++) {
        keccak.inPaddedHex[idx] <== pad.out[idx];
    }
    keccak.rounds <== 5 - leq.out;

    for (var idx = 0; idx < 32; idx++) {
        // flip the 2 hexes of each byte, for some reason.
        // guessing small endian/big endian
        currentHash[2 * idx] <== keccak.out[2 * idx + 1];
        currentHash[2 * idx + 1] <== keccak.out[2 * idx];
    }
    for (var idx = 0; idx < 64; idx++) {
        // grab parenthash and mixhash from the RLP/block header, for output
        parentHash[idx] <== rlp.fields[0][idx];
        mixHash[idx] <== rlp.fields[13][idx];
    }
    for (var idx = 0; idx < 6; idx++) {
        blockNumber[idx] <== rlp.fields[8][idx];
    }

    // Logging decoded RLP values
    for (var idx = 0; idx < 64; idx++) {
        log(currentHash[idx]);
    }
    for (var idx = 0; idx < 6; idx++) {
        log(blockNumber[idx]);
    }
    for (var idx = 0; idx < 64; idx++) {
        log(parentHash[idx]);
    }
    for (var idx = 0; idx < 64; idx++) {
        log(mixHash[idx]);
    }
 }

component main = SingleEthBlockHashHex(1112);