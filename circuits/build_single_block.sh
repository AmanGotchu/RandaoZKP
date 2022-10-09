#!/bin/bash

PHASE1=/powers-of-tau/powersOfTau28_hez_final_25.ptau
BUILD_DIR=$BUILD_DIR
TRUSTED_SETUP_DIR=../trusted_setup/

CIRCUIT_NAME=singleBlockHeader

if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory found. Creating build directory..."
    mkdir "$BUILD_DIR"
fi

echo $PWD

echo "**** COMPILING CIRCUIT $CIRCUIT_NAME.circom ****"
start=`date +%s`
circom "$CIRCUIT_NAME".circom --O1 --r1cs --wasm --c --sym --output "$BUILD_DIR"
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=`date +%s`
node "$BUILD_DIR"/"$CIRCUIT_NAME"_js/generate_witness.js \
    "$BUILD_DIR"/"$CIRCUIT_NAME"_js/"$CIRCUIT_NAME".wasm ../scripts/input_15705750.json \
    "$BUILD_DIR"/witness.wtns
end=`date +%s`
echo "DONE ($((end-start))s)"

if [ -f "$PHASE1" ]; then
    echo "Found Phase 1 ptau file"
else
    echo "No Phase 1 ptau file found. Exiting..."
    exit 1
fi

# these need powers of tau...
if test ! -f "$TRUSTED_SETUP_DIR/vkey.json"; then
    echo "****GENERATING ZKEY 0****"
    start=`date +%s`
    NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs groth16 setup "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME"_0.zkey
    end=`date +%s`
    echo "DONE ($((end-start))s)"

    echo "****GENERATING FINAL ZKEY****"
    start=`date +%s`
    NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs zkey beacon "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME"_0.zkey "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME".zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"
    end=`date +%s`
    echo "DONE ($((end-start))s)"

    echo "****VERIFYING FINAL ZKEY****"
    start=`date +%s`
    NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs zkey verify -verbose "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME".zkey
    end=`date +%s`
    echo "DONE ($((end-start))s)"

    echo "****EXPORTING VKEY****"
    start=`date +%s`
    npx snarkjs zkey export verificationkey "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME".zkey "$TRUSTED_SETUP_DIR"/vkey.json
    end=`date +%s`
    echo "DONE ($((end-start))s)"
fi

echo "****GENERATING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 prove "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 verify "$TRUSTED_SETUP_DIR"/vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
end=`date +%s`
echo "DONE ($((end-start))s)"

# generate the solidity verifier contract
snarkjs zkey export solidityverifier "$TRUSTED_SETUP_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/"$CIRCUIT_NAME"_verifier.sol
