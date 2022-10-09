import { execSync } from "child_process";
import { writeBlockHeaderRLP } from "./getBlockHeaders";
import fs from 'fs';
import { BigNumber } from "ethers";

const sendProofTx = () => {

}

const triggerProofSubmission = () => {
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
}

triggerProofSubmission();