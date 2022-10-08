pragma circom 2.0.3;

include "../circom-pairing/circuits/bn254/groth16.circom";

template Example () {
    signal input a;
    signal input b;
    signal input c;

    c === a * b;
}

component main { public [ c ] } = Example();

/* INPUT = {
    "a": "5",
    "b": "77",
    "c": "385"
} */