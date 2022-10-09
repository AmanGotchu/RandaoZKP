import { execSync } from "child_process";
import { writeBlockHeaderRLP } from "./getBlockHeaders";
import fs from 'fs';
import { BigNumber, ethers } from "ethers";
import * as dotenv from 'dotenv'

const triggerProofSubmission = async () => {
    dotenv.config({path: "../.env"});

    const blockNum = 101;
    const build_dir = `./proofstuff_${blockNum}`;

    // // Block header write
    writeBlockHeaderRLP(blockNum);

    // // Proof orchestration
    let output = execSync(  './generateProof.sh',{encoding: 'utf-8', env: {
        BLOCK_NUM: blockNum + "",
        BUILD_DIR: `../scripts/proofstuff_${blockNum}`,
        PATH: process.env.PATH
    }});
    console.log('Output was:\n', output);

    // Construct proof submission and send ethers transaction
    const proofFilePath = `${build_dir}/proof.json`;
    const publicFilePath = `${build_dir}/public.json`;

    if (!fs.existsSync(proofFilePath) || !fs.existsSync(publicFilePath)) {
        throw new Error("Proof or public json files don't exist!");
    }

    const proofData = JSON.parse(fs.readFileSync(proofFilePath).toString());
    const publicData = JSON.parse(fs.readFileSync(publicFilePath).toString());

    const aIn: BigNumber[] = [BigNumber.from(proofData.pi_a[0]), BigNumber.from(proofData.pi_a[1])];
    const bIn: BigNumber[][] = [[BigNumber.from(proofData.pi_b[0][0]), BigNumber.from(proofData.pi_b[0][0])],[BigNumber.from(proofData.pi_b[1][0]),BigNumber.from(proofData.pi_b[1][1])]];
    const cIn: BigNumber[] = [proofData.pi_c[0], proofData.pi_c[1]];

    const pubIn: BigNumber[] = publicData.map((data: number) => {
        return BigNumber.from(data);
    })

    // Contract call
    let { RPC_URL, RPC_API_KEY } = process.env;
    const endpoint = `${RPC_URL}${RPC_API_KEY}`;

    const provider = new ethers.providers.JsonRpcProvider(endpoint);
    const faucetContract = new ethers.Contract(
        "faucetContractAddress",
        new ethers.utils.Interface([
            `function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[198] memory input) public view returns (bool r)`,
        ]),
        provider
    );

    const res = await faucetContract.verifyProof(aIn, bIn, cIn, pubIn);
    console.log("Verify proof result:", res);
}

triggerProofSubmission();