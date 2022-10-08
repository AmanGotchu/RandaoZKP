import { ethers } from "ethers";
import axios from "axios";
import { write } from "fs";
var minimist = require("minimist");

const RLP_LENGTH = 1112;

var args = minimist(process.argv.slice(2), {
  number: ["blocknum"], // --blocknum 2398572498
  boolean: ["is_base"],
  default: { is_base: false },
});

const getBlockHeader = async (blockNumber: bigint | null) => {
  console.log(`getting block header ${blockNumber}`);
  return axios.post(
    "https://mainnet.infura.io/v3/b21f394fcb224f8781403d4bf6caf604",
    {
      jsonrpc: "2.0",
      id: 0,
      method: "eth_getBlockByNumber",
      params: [blockNumber ? "0x" + blockNumber.toString(16) : "latest", false],
    }
  );
};

const getLatestBlock = async () => {
  // if blocknum is null/unspecified, just latest
  if (args.blocknum === null) {
    console.log("setting default blocknum");
    const latestBlock = await getBlockHeader(null);
    console.log(JSON.stringify(latestBlock.data.result));
    args.blocknum = latestBlock.data.result.number;
    console.log(`set blocknum to latest ${args.blocknum}`);
    return latestBlock;
  }
};

const writeBlockHeaderRLP = async (blocknum: bigint) => {
  const blockHeaderResp = await getBlockHeader(blocknum);

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
    baseBit: args.is_base ? 1 : 0,
  };
  const jsonfile = require("jsonfile");

  const file = `input_${blocknum}.json`;

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

  console.log(blockHeaderInputs);
  console.log(rlpEncodedHeader);

  return rlpEncodedHeader;
};

writeBlockHeaderRLP(args.blocknum);
