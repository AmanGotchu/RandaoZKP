import { execSync } from "child_process";
import { writeBlockHeaderRLP } from "./getBlockHeaders";
import fs from 'fs';
import { ethers } from "ethers";
import * as dotenv from 'dotenv'

export const poke = async () => {
    let { RPC_URL, PV_KEY } = process.env;
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const signer = new ethers.Wallet(PV_KEY!, provider);
    const verifierContract = new ethers.Contract(
        process.env.VERIFIER_CONTRACT_ADDRESS!,
        new ethers.utils.Interface([
            `function prove(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[198] memory input) public`,
            `function poke() public`
        ]),
        signer
    );
    verifierContract.connect(signer);

    const tx = await verifierContract.poke({
        gasLimit: 1_000_000
    });
    const res = await tx.wait();
    return res;
}

export const triggerProofSubmission = async (blockNum: number) => {
    dotenv.config({
        path: "../.env"
    })
    // Block header write
    console.log("Writing block header!");
    await writeBlockHeaderRLP(blockNum);

    // Proof orchestration
    console.log("Running proof generation orchestration!");
    let output = execSync('./generateProof.sh',{encoding: 'utf-8', env: {
        BLOCK_NUM: blockNum + "",
        BUILD_DIR: `../scripts/proofstuff_${blockNum}`,
        PATH: process.env.PATH
    }});
    console.log('Output was:\n', output);

    console.log("Constructing calldata for proof submission!");

    const calldataPath = `../scripts/proofstuff_${blockNum}/calldata.txt`;
    if (!fs.existsSync(calldataPath)) {
        throw new Error("Calldata path doesn't exist!");
    }

    console.log("Calling contract!");
    const calldata = JSON.parse("[" + fs.readFileSync(calldataPath).toString() + "]");
    let { RPC_URL, PV_KEY } = process.env;
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const signer = new ethers.Wallet("0x93bf309c2c473731ce11cb548b8986c19660e81f70459b6150b20b55f5413f1a", provider);
    const verifierContract = new ethers.Contract(
        process.env.VERIFIER_CONTRACT_ADDRESS!,
        new ethers.utils.Interface([
            `function prove(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[198] memory input) public`,
            `function poke() public`
        ]),
        signer
    );
    verifierContract.connect(signer);
    const aIn = calldata[0];
    const bIn = calldata[1];
    const cIn = calldata[2];
    const pubIn = calldata[3];

    const res = await verifierContract.prove(aIn, bIn, cIn, pubIn, {
        gasLimit: 20000000
    })
    console.log("Submitted Transaction");
    const tx = await res.wait();
    console.log("Transaction submitted!");
    return tx;
}
