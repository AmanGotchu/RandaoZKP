import fs from 'fs';
import * as dotenv from 'dotenv'
import { writeBlockHeaderRLP } from './getBlockHeaders';
import path from 'path';

const generateProof = async () => {
    var minimist = require("minimist");
    var { blockNumber } = minimist(process.argv.slice(2));

    dotenv.config({
        path: "../.env"
    });
    console.log(process.env);

    const dir = `proofstuff_${blockNumber}`;
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir);
    }

    // Construct input.json
    const inputFilePath = `./${dir}/input.json`;
    await writeBlockHeaderRLP(blockNumber, inputFilePath);

    // Set output build 
    process.env.BUILD_DIR="./proofstuff_100/build"

    // Generate witness using input.json
    const execSync = require('child_process').execSync;

    var circuitsDir = path.resolve(process.cwd(), '../circuits');
        const output = execSync('./build_single_block.sh', { encoding: 'utf-8', cwd: circuitsDir, 
        shell: "/bin/zsh",
        env: {
            BUILD_DIR: "../scripts/proofstuff_100/build",
        }});

    console.log('Output was:\n', output);

    // Generate proof using compiled r1cs & witness file

    // Use generated proof.json and public.json and send a ETH tx to our Goerli verifier contract
}

generateProof();