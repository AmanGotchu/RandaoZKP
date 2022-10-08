pragma circom 2.0.3;

include "../circom-pairing/circuits/bn254/groth16.circom";

template Example () {
    signal input a;
    signal input b;
    signal input c;

    // bn256 fact
    var k2=6;
    
    // inner verification key and proof
    signal input negalfa1xbeta2[6][2][k2]; // e(-alfa1, beta2)
    signal input gamma2[2][2][k2];
    signal input delta2[2][2][k2];
    signal input IC[2][2][k2];
    signal input negpa[2][k2];
    signal input pb[2][2][k2];
    signal input pc[2][k2];

    c === a * b;

    component groth16Verifier = verifyProof(1);
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
                groth16Verifier.IC[i][j][idx] <== IC[i][j][idx];
                groth16Verifier.pb[i][j][idx] <== pb[i][j][idx];                
            }
        }
    }

    for (var i = 0;i < 2;i++) {
        for (var idx = 0;idx < k2;idx++) {
            groth16Verifier.negpa[i][idx] <== negpa[i][idx];
            groth16Verifier.pc[i][idx] <== pc[i][idx];
        }
    }
    groth16Verifier.pubInput[0] <== b;

    component cIs1 = IsEqual();
    cIs1.in[0] <== c;
    cIs1.in[1] <== 1;

    component innermostORcorrect = OR();
    innermostORcorrect.a <== cIs1.out;
    innermostORcorrect.b <== groth16Verifier.out;

    innermostORcorrect.out === 1;
}

component main { public [ c ] } = Example();

/* INPUT = {
    "a": "5",
    "b": "77",
    "c": "385"
} */