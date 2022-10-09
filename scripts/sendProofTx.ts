import { execSync } from "child_process";


const sendProofTx = () => {
    const exec = require('child_process').exec
    const blockNum = "101";

    let child = execSync('./generateProof.sh',{shell: '/bin/zsh', env: {
        BLOCK_NUM: blockNum,
        BUILD_DIR: `../scripts/proofstuff_${blockNum}`
    }});
}

sendProofTx();