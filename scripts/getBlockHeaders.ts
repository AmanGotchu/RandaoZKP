import { ethers } from "ethers";
import axios from "axios";
import fs from 'fs';

// usage: $yarn ts-node getBlockHeaders.ts --blocknum 15705750
var minimist = require("minimist");

const RLP_LENGTH = 1112;

export const writeBlockHeaderRLP = async (blocknum: number) => {
  let { RPC_URL, RPC_API_KEY } = process.env;
  RPC_URL = RPC_URL || "https://mainnet.infura.io/v3/";

  const blockHeaderResp = await axios.post(`${RPC_URL}${RPC_API_KEY}`, {
    jsonrpc: "2.0",
    id: 0,
    method: "eth_getBlockByNumber",
    params: [blocknum ? "0x" + blocknum.toString(16) : "latest", false],
  });

  let encoded = encodeRLP(blockHeaderResp);
  // super long string that looks like
  /*
  0xf90202a044ed7e4de93c5b2d45d24c2fbcdeaeb094e4d2615a910a0f3e6dce7afe165db5a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794ba9431d1975b5131e496f8398d6e6b4e4a08fd05a0b857fc41efdb7f136b365f9cefd54f9455c0bbd34869db87cfaab825a93c47f1a097fcd4e132664c1faadbb07d004089f146ed6127c2856d66ec717ecd12ff63f7a0a366e88c9e9bd472eacc422fcc5acd9d6d70169c749581013a5f6af04051b9f1b9010020610546f783dea1e1270301c71041706da4424c0090033601f384e2791cbc033cd014285c00590814ec5722240803c24e48495a1ac9b3f098100348407e2c18255041144dcdb428f882d92c5f007c204ac19426044e57025d9598a5c961582126154024125f464e0618b45e92a9381d3a1769e535f554e0e60090f09a6b0b2c0a00a7504006717990cf0138ad225106642264c34b22841bff9a4865c87312229b825933c2cfe4408a8141c4f7c10d4ecfc50fa705082012dc070d4eb66c8d590744200a67a169f141990d2209935b145d3e08eed52183741696bbd2881b7e80003ca0495480460e5a1979c817879a00c5ea1888603c1cf1cfecf85e2a13758f8083efa6968401c9c3808401538fe5846341dcd780a01fbef5b47c7ce095d3780cc01755575fd823b44c96d00aa703fe01a99a7d72d8880000000000000000850908bfe131
  */

  // remove 0x prefix
  encoded = encoded.replace("0x", "");

  const padLen = 1112 - encoded.length;
  if (padLen > 0) {
    encoded += "0".repeat(padLen);
  }

  const rlpHexEncoded = [...encoded].map((char) => parseInt(char, 16));
  console.log(`length is ${rlpHexEncoded.length}`);

  const output = {
    rlpHexEncoded: rlpHexEncoded,
    //    baseBit: args.is_base ? 1 : 0,
  };
  console.log(output);
  const jsonfile = require("jsonfile");

  const dir = `proofstuff_${blocknum}`;
  if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir);
  }
  const file = `./proofstuff_${blocknum}/input_${blocknum}.json`;

  jsonfile.writeFile(file, output, function (err: any) {
    if (err) console.error(err);
  });

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

  const LONDON_HARDFORK_BLOCK = 12965000;
  if (number > LONDON_HARDFORK_BLOCK) {
    blockHeaderInputs["baseFeePerGas"] = baseFeePerGas;
  }

  Object.keys(blockHeaderInputs).map((key: string) => {
    let val = blockHeaderInputs[key];

    // All 0 values for these fields must be 0x
    if (["gasLimit", "gasUsed", "time", "difficulty", "number"].includes(key)) {
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

  return rlpEncodedHeader;
};
