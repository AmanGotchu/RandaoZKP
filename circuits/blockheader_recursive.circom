pragma circom 2.0.2;

include "../circom-pairing/node_modules/circomlib/circuits/bitify.circom";
include "../circom-pairing/node_modules/circomlib/circuits/comparators.circom";
include "../circom-pairing/node_modules/circomlib/circuits/multiplexer.circom";
include "../circom-pairing/circuits/bn254/groth16.circom";

include "./utils/keccak.circom";
include "./utils/rlp.circom";
include "./utils/mpt.circom";

// Recursive ZKP of block header values
template EthBlockHashHexRecursive(publicInputCount) {
    var k2 = 6;
    var publicInputCount = 130; // TODO(aman): Figure out exactly what this is for new circuit

    signal input iter; // Keeps track of recursion depth
    signal input proofBlockHashHexs[64]; // Overall block header we're proving
    signal input blockRlpHexs[1112]; // Current Block Header we're proving

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
    signal output blockHashHexs[64]; // Current block's hash

    signal output iterOut; // Recursion depth
    iterOut <== iter + 1;

    signal output proofBlockHashHexsOut[64]; // Overall block hash we're proving for
    for (var idx = 0; idx < 64; i++) {
        proofBlockHashHexsOut[idx] <== proofBlockHashHexs[idx];
    }

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
    component leq = LessEqThanLessThan(13);
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

    component parentHash[64];
    for (var idx = 0; idx < 64; idx++) {
        parentHash[idx] <== rlp.fields[0][idx];
    }

    // Logging decoded RLP values
    for (var idx = 0; idx < 64; idx++) {
        log(blockHashHexs[idx]);
    }

    for (var idx = 0; idx < 64; idx++) {
        log(parentHash[idx]);
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

    // Proof validators
    component proofValidation = MultiAND(128);
    component eq[128];
    for (var i = 0; i<64; i++) {
        // TODO(aman): Make pubInput is indexing properly!

        // Verifies current parent hash matches proof's block hash
        eq[2*i] = IsEqual();
        eq[2*i].in[0] <== pubInput[1+i];
        eq[2*i].in[1] <== parentHash[i];
        proofValidation.in[2*i] <== eq[2*i].out;

        // Verifies that the proof is proving the same overall block as this circuit
        eq[2*i+1] = IsEqual();
        eq[2*i+1].in[0] <== pubInput[66+i];
        eq[2*i+1].in[1] <== proofBlockHashHexs[i];
        proofValidation.in[2*i+1] <== eq[2*i+1].out;
    }

    // Ensure the current iter is the proof's output iter
    iter === pubInput[0];

    component validVerifier = AND();
    validVerifier.a <== proofValidation.out;
    validVerifier.b <== groth16Verifier.out;

    component baseBitOrValidVerifier = OR();
    baseBitOrValidVerifier.a <== baseBit;
    baseBitOrValidVerifier.b <== validVerifier.out;

    component processedVerifierOutAndRLPOut = AND();
    processedVerifierOutAndRLPOut.a <== baseBitOrValidVerifier.out;
    processedVerifierOutAndRLPOut.b <== rlp.out;
    processedVerifierOutAndRLPOut.out === 1;

    // out = rlp_out AND (NOT base_bit OR (verifier_out AND hash_match_out))
    out <== processedVerifierOutAndRLPOut.out;
    log(out);
}

component main = EthBlockHashHexRecursive();