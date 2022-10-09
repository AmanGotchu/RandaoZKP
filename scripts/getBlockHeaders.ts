import { ethers } from "ethers";
import axios from "axios";
import fs from 'fs';
import * as dotenv from 'dotenv';

// usage: $yarn ts-node getBlockHeaders.ts --blocknum 15705750
var minimist = require("minimist");

const RLP_LENGTH = 1112;

export const writeBlockHeaderRLP = async (blocknum: number) => {
  dotenv.config({
    path: "../.env"
  })

  let { RPC_URL } = process.env;

  const blockHeaderResp = await axios.post(RPC_URL!, {
    jsonrpc: "2.0",
    id: 0,
    method: "eth_getBlockByNumber",
    params: [
      blocknum ? "0x" + blocknum.toString(16) : "latest", false],
  });

  let encoded = encodeRLP(blockHeaderResp);
  // super long string that looks like
  /*
  0xf90202a044ed7e4de93c5b2d45d24c2fbcdeaeb094e4d2615a910a0f3e6dce7afe165db5a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794ba9431d1975b5131e496f8398d6e6b4e4a08fd05a0b857fc41efdb7f136b365f9cefd54f9455c0bbd34869db87cfaab825a93c47f1a097fcd4e132664c1faadbb07d004089f146ed6127c2856d66ec717ecd12ff63f7a0a366e88c9e9bd472eacc422fcc5acd9d6d70169c749581013a5f6af04051b9f1b9010020610546f783dea1e1270301c71041706da4424c0090033601f384e2791cbc033cd014285c00590814ec5722240803c24e48495a1ac9b3f098100348407e2c18255041144dcdb428f882d92c5f007c204ac19426044e57025d9598a5c961582126154024125f464e0618b45e92a9381d3a1769e535f554e0e60090f09a6b0b2c0a00a7504006717990cf0138ad225106642264c34b22841bff9a4865c87312229b825933c2cfe4408a8141c4f7c10d4ecfc50fa705082012dc070d4eb66c8d590744200a67a169f141990d2209935b145d3e08eed52183741696bbd2881b7e80003ca0495480460e5a1979c817879a00c5ea1888603c1cf1cfecf85e2a13758f8083efa6968401c9c3808401538fe5846341dcd780a01fbef5b47c7ce095d3780cc01755575fd823b44c96d00aa703fe01a99a7d72d8880000000000000000850908bfe131
  */

  // remove 0x prefix
  encoded = encoded.replace("0x", "");
  const rlpHexEncoded = [...encoded].map((char) => parseInt(char, 16));
  console.log(`length is ${rlpHexEncoded.length}`);

  const padLen = 1112 - rlpHexEncoded.length;
  for (let i = 0; i<padLen; i++)
  if (padLen > 0) {
    rlpHexEncoded.push(0);
  }

  console.log(`final length is ${rlpHexEncoded.length}`);

  const output = {
    blockRlpHexs: rlpHexEncoded,
    //    baseBit: args.is_base ? 1 : 0,
  };
  console.log(output);
  const jsonfile = require("jsonfile");

  const dir = `proofstuff_${blocknum}`;
  if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir);
  }
  const file = `./proofstuff_${blocknum}/input.json`;

  jsonfile.writeFileSync(file, output);
  return;
};

const encodeRLP = (blockHeaderResp: any) => {
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
    hash, // For comparison afterwards
  } = blockHeaderResp.data.result;

  // Construct bytes like input to RLP encode function
  const blockHeaderInputs: { [key: string]: string } = {
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
  };

  const LONDON_HARDFORK_BLOCK = 5062605;
  if (number > LONDON_HARDFORK_BLOCK) {
    blockHeaderInputs["baseFeePerGas"] = baseFeePerGas;
  }

  Object.keys(blockHeaderInputs).map((key: string) => {
    let val = blockHeaderInputs[key];

    // All 0 values for these fields must be 0x
    if (["gasLimit", "gasUsed", "timestamp", "difficulty", "number"].includes(key)) {
      if (parseInt(val, 16) === 0) {
        val = "0x";
      }
    }

    // Pad hex for proper Bytes parsing
    if (val.length % 2 == 1) {
      val = val.substring(0, 2) + "0" + val.substring(2);
    }

    blockHeaderInputs[key] = val;
  });

  const rlpEncodedHeader = ethers.utils.RLP.encode(
    Object.values(blockHeaderInputs)
  );

  const derivedBlockHash = ethers.utils.keccak256(rlpEncodedHeader);

  console.log("=========================");
  console.log("Block Number", number);
  console.log("Mix hash", mixHash);
  console.log("RLP Derived Block Hash", derivedBlockHash);
  console.log("Actual Block Hash", hash);
  if (derivedBlockHash !== hash) {
    console.error("Not correct!");
  }

  return rlpEncodedHeader;
};

writeBlockHeaderRLP(7739551);

// const res = [15,9,0,2,1,5,10,0,8,11,8,14,6,6,6,14,1,14,5,5,14,13,3,1,5,14,0,5,15,4,10,13,2,8,8,11,13,1,8,3,2,3,13,10,0,9,1,15,5,6,7,1,9,9,9,12,2,4,14,7,15,9,10,7,1,0,3,15,14,4,0,12,10,0,1,13,12,12,4,13,14,8,13,14,12,7,5,13,7,10,10,11,8,5,11,5,6,7,11,6,12,12,13,4,1,10,13,3,1,2,4,5,1,11,9,4,8,10,7,4,1,3,15,0,10,1,4,2,15,13,4,0,13,4,9,3,4,7,9,4,14,10,6,7,4,15,13,13,14,7,1,4,15,13,9,7,9,13,14,3,14,13,15,0,15,5,6,10,10,9,7,1,6,11,8,9,8,14,12,8,10,0,14,12,11,11,9,6,4,4,10,10,0,0,1,13,10,12,6,10,4,10,9,2,14,0,6,0,12,11,0,3,9,5,8,4,15,10,4,12,8,13,9,6,10,3,2,7,13,3,0,0,5,5,13,1,3,1,13,10,4,1,12,7,15,13,10,0,14,9,3,15,15,13,0,13,0,8,14,9,6,12,6,4,5,1,11,4,13,13,3,13,12,9,10,11,6,4,7,7,7,4,0,13,4,7,6,1,9,0,14,13,12,3,5,0,15,12,9,5,9,11,1,3,15,3,11,9,11,5,2,9,10,0,5,3,1,12,2,12,9,13,11,6,0,15,6,6,7,13,10,0,4,15,6,14,6,8,13,0,6,9,11,11,0,0,10,10,2,11,1,11,8,15,3,14,13,3,0,11,15,4,3,11,9,5,15,6,15,4,8,2,8,1,3,0,12,5,11,9,0,1,0,0,8,2,12,0,15,9,12,10,4,0,2,0,1,4,8,8,4,9,0,2,6,10,2,10,0,0,8,10,6,0,4,11,2,0,14,5,2,4,6,11,0,10,4,7,0,2,4,15,10,4,8,0,15,11,12,3,8,3,0,2,0,4,8,1,13,5,0,10,4,3,1,6,0,7,2,11,2,0,8,0,0,9,10,12,0,6,4,0,12,4,9,14,10,6,4,2,9,2,12,0,4,4,14,0,4,13,11,13,1,8,0,1,0,0,0,10,7,4,4,0,6,0,11,8,10,9,1,12,4,2,2,3,0,4,8,3,10,4,0,9,0,2,0,3,4,13,0,7,1,8,0,8,3,0,2,1,4,0,10,8,1,2,0,8,10,1,8,0,4,6,6,1,12,2,2,8,0,1,1,11,14,9,1,4,0,8,4,2,4,1,5,0,6,0,0,0,5,2,0,8,5,10,12,0,5,8,0,0,2,2,9,11,0,6,4,4,2,6,0,5,8,8,2,13,7,4,1,10,5,2,8,4,2,14,5,0,1,0,8,8,11,4,0,1,0,13,7,1,2,0,0,0,1,11,1,0,8,0,15,5,8,8,6,6,0,0,2,5,0,0,1,7,0,9,1,3,0,13,13,3,10,0,6,7,3,4,1,8,9,13,1,8,13,8,7,11,4,1,8,0,10,3,4,2,2,9,0,3,15,1,14,0,2,0,4,0,2,0,3,10,0,14,0,5,10,8,0,3,6,2,0,9,2,12,0,0,7,6,10,2,0,12,0,4,8,0,4,8,15,12,2,3,1,10,13,2,0,2,0,8,8,1,10,0,2,0,0,4,6,0,9,0,0,3,6,0,3,10,11,13,10,0,4,8,2,0,1,8,8,8,2,2,0,5,1,10,0,7,0,0,0,0,1,8,4,2,11,1,9,13,1,12,0,14,12,8,8,11,8,0,2,4,8,7,0,1,2,8,1,10,0,5,2,9,1,1,4,6,8,9,6,5,0,3,2,8,8,1,3,4,9,5,2,10,11,8,0,8,4,4,0,3,0,14,3,0,0,2,5,0,8,9,8,4,1,0,14,3,8,2,1,2,0,0,8,10,2,13,1,11,4,3,11,0,9,5,3,4,2,0,6,8,0,8,0,5,8,2,13,12,8,0,8,7,0,6,14,7,2,3,1,9,9,11,12,13,0,11,8,3,7,6,1,7,6,13,8,3,7,10,1,2,0,0,8,3,7,10,0,15,9,10,8,4,5,12,13,6,12,1,8,11,9,4,5,0,5,0,5,9,4,5,2,13,6,5,7,4,6,8,6,5,7,2,6,13,6,9,6,14,6,5,2,13,6,5,7,5,3,1,2,13,3,8,10,0,12,15,1,2,11,14,15,0,13,9,7,9,4,9,8,6,10,1,13,4,10,5,4,4,1,5,10,9,3,12,2,1,11,0,2,14,10,9,13,4,14,0,11,8,1,8,3,4,3,0,6,14,13,12,3,5,0,3,12,0,2,3,8,1,8,8,12,4,0,11,2,3,14,0,0,1,9,6,14,13,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
// console.log(res.length);