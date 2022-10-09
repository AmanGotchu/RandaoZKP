import { ethers } from 'ethers';
import axios from 'axios';

const verifyRLPEncoding = async () => {
    const { height } = require('minimist')(process.argv.slice(2));

    const block: any = await axios.post('https://goerli.infura.io/v3/b21f394fcb224f8781403d4bf6caf604', {
        "jsonrpc":"2.0",
        "id":0,
        "method":"eth_getBlockByNumber",
        "params": [
            height ? "0x" + height.toString(16) : "latest",
            false
        ]
    });

    const {
        parentHash,
        sha3Uncles,
        miner, // Coinbase
        stateRoot,
        transactionsRoot,
        receiptsRoot,
        logsBloom,
        difficulty,
        number,
        gasLimit,
        gasUsed,
        timestamp,
        extraData,
        mixHash,
        nonce,
        baseFeePerGas, // For Post 1559 blocks
        hash // For comparison afterwards
    } = block.data.result;

    console.log("Mix Hash:", mixHash);
    console.log("Difficulty:", difficulty);

    // Construct bytes like input to RLP encode function
    const blockHeaderInputs: {[key: string]: string} = {
        parentHash,
        sha3Uncles,
        miner, // Coinbase
        stateRoot,
        transactionsRoot,
        receiptsRoot,
        logsBloom,
        difficulty,
        number,
        gasLimit,
        gasUsed,
        timestamp,
        extraData,
        mixHash,
        nonce,
    }

    const LONDON_HARDFORK_BLOCK = 5062605;
    if (number > LONDON_HARDFORK_BLOCK) {
        blockHeaderInputs['baseFeePerGas'] = baseFeePerGas;
    }

    Object.keys(blockHeaderInputs).map((key: string) => {
        let val = blockHeaderInputs[key];

        // All 0 values for these fields must be 0x
        if (['gasLimit', 'gasUsed', 'time', 'difficulty', 'number'].includes(key)) {
            if (parseInt(val, 16) === 0) {
                val = "0x";
            }
        }

        // Pad hex for proper Bytes parsing
        if (val.length % 2 == 1) {
            val = val.substring(0,2) + "0" + val.substring(2);
        }

        blockHeaderInputs[key] = val;
    })

    const rlpEncodedHeader = ethers.utils.RLP.encode(Object.values(blockHeaderInputs));
    const derivedBlockHash = ethers.utils.keccak256(rlpEncodedHeader);

    console.log("Block Number", number);
    console.log("Mix hash", mixHash);
    console.log("Derived Block Hash", derivedBlockHash);
    console.log("Actual Block Hash", hash);
    console.log("=========================")

    if (derivedBlockHash === hash) {
        console.log("SUCCESS! Derived matches expected", derivedBlockHash);
    } else {
        throw new Error(`Derived ${derivedBlockHash} DOES NOT match expected ${hash}`)
    }
}

verifyRLPEncoding();
