import { execSync } from "child_process";
import { writeBlockHeaderRLP } from "./getBlockHeaders";
import fs from 'fs';
import { BigNumber, ethers } from "ethers";
import * as dotenv from 'dotenv'

export const poke = async () => {
    let { RPC_URL, PV_KEY } = process.env;
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const signer = new ethers.Wallet(PV_KEY!, provider);
    const verifierContract = new ethers.Contract(
        "0x948279128B8F7b62cb9C6Bfce0905aFba9cbd116",
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
    // Block header write
    console.log("Writing block header!");
    writeBlockHeaderRLP(blockNum);

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
    const signer = new ethers.Wallet(PV_KEY!, provider);
    const verifierContract = new ethers.Contract(
        "0x948279128B8F7b62cb9C6Bfce0905aFba9cbd116",
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
    const tx = await res.wait();
    console.log("Transaction submitted!");
    return tx;
}
