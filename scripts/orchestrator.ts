/*
    1. Input blocks we want to prove

    Run for each block
    2. Generate inputs for the proof
        - Fetch RLP encoded headers for a block from dlee's javascript script
        - Fetch vk & proof inputs from python conversion script
        - Combine into single input.json for circuit witness generation
    3. Generate witnesses using previously created input.json & circuit r1cs (assuming r1cs & vk exist)
    4. Generate proof given zkey (Zkey is created from r1cs so is constant. It contains both pkey & vkey, this is used to export vk) and wtns)
    5. Store proof somewhere such that it can be fed into Step 2.
    6. The last proof is the one we post! This proof proves that the public data (output) is tied to the block we're proving!
*/

const main = function(desiredBlockHeight: number, checkpointBlockHeight: number) {
    // Need to provide proofs all the way to checkpointBlock inclusive
    for (let block = desiredBlockHeight; block <= checkpointBlockHeight; block++) {
        
    }
}