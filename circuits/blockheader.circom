pragma circom 2.0.2;

include "../circom-pairing/node_modules/circomlib/circuits/bitify.circom";
include "../circom-pairing/node_modules/circomlib/circuits/comparators.circom";
include "../circom-pairing/node_modules/circomlib/circuits/multiplexer.circom";
include "../circom-pairing/circuits/bn254/groth16.circom";

include "./utils/keccak.circom";
include "./utils/rlp.circom";
include "./utils/mpt.circom";

// State, TX, Receipts, Number, Parent hash, Mix hash (block randomness)
template EthBlockHashHex(publicInputCount) {
    // // ecdsa fact
    // var n1 = 64;
    // var k1 = 4;

    // bn254 fact
    var k2 = 6;

    signal input blockRlpHexs[1112]; // 1112 bytes of RLP encoding
    signal input baseBit;

    // verification key inputs
    signal input negalfa1xbeta2[6][2][k2]; // e(-alfa1, beta2)
    signal input gamma2[2][2][k2];
    signal input delta2[2][2][k2];
    signal input IC[publicInputCount+1][2][k2];

    // proof inputs
    signal input negpa[2][k2];
    signal input pb[2][2][k2];
    signal input pc[2][k2];
    signal input pubInput[publicInputCount];

    // Outputs
    signal output out; // Returns 0 or 1
    signal output blockHashHexs[64];
    signal output numberHexLen;
    signal output parentHash[64];
    signal output number[6];
    signal output mixHash[64];

    // Decoding RLP input
    log(555555500001);
    for (var idx = 0; idx < 1112; idx++) {
        log(blockRlpHexs[idx]);
    }

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
        mixHash[idx] <== rlp.fields[13][idx];
    }
    numberHexLen <== rlp.fieldHexLen[8];
    for (var idx = 0; idx < 6; idx++) {
        number[idx] <== rlp.fields[8][idx];
    }

    // Logging decoded RLP values
    for (var idx = 0; idx < 64; idx++) {
        log(blockHashHexs[idx]);
    }
    log(numberHexLen);
    for (var idx = 0; idx < 6; idx++) {
        log(number[idx]);
    }
    for (var idx = 0; idx < 64; idx++) {
        log(parentHash[idx]);
    }
    for (var idx = 0; idx < 64; idx++) {
        log(mixHash[idx]);
    }

    // Instantiating Groth16 verifier and inputs
    component groth16Verifier = verifyProof(publicInputCount);
    for (var i = 0;i < 6;i++) {
        for (var j = 0;j < 2;j++) {
            for (var idx = 0;idx < k2;idx++) {
                groth16Verifier.negalfa1xbeta2[i][j][idx] <== negalfa1xbeta2[i][j][idx];
            }
        }
    }

    for (var i = 0;i < 2;i++) {
        for (var j = 0;j < 2;j++) {
            for (var idx = 0;idx < k2;idx++) {
                groth16Verifier.gamma2[i][j][idx] <== gamma2[i][j][idx];
                groth16Verifier.delta2[i][j][idx] <== delta2[i][j][idx];
                groth16Verifier.pb[i][j][idx] <== pb[i][j][idx];                
            }
        }
    }

    for (var i = 0;i < publicInputCount+1;i++) {
        for (var j = 0;j < 2;j++) {
            for (var idx = 0;idx < k2;idx++) {
                groth16Verifier.IC[i][j][idx] <== IC[i][j][idx];        
            }
        }
    }

    for (var i = 0;i < 2;i++) {
        for (var idx = 0;idx < k2;idx++) {
            groth16Verifier.negpa[i][idx] <== negpa[i][idx];
            groth16Verifier.pc[i][idx] <== pc[i][idx];
        }
    }

    // Assign previous outputs as verify inputs
    for (var i = 0; i<publicInputCount; i++) {
        groth16Verifier.pubInput[i] <== pubInput[i];
    }

    // TODO(aman): Add check that ensures pubInput's block hash equates to the parent hash of the RLP encoded input

    component baseBitOrVerifierOut = OR();
    baseBitOrVerifierOut.a <== baseBit;
    baseBitOrVerifierOut.b <== groth16Verifier.out;

    component processedVerifierOutAndRLPOut = AND();
    processedVerifierOutAndRLPOut.a <== baseBitOrVerifierOut.out;
    processedVerifierOutAndRLPOut.b <== rlp.out;

    // out = rlp_out AND (NOT base_bit OR verifier_out)
    out <== processedVerifierOutAndRLPOut.out;
    log(out);
}