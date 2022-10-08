import { ethers } from "ethers";
import axios from "axios";
var minimist = require("minimist");

var args = minimist(process.argv.slice(2), {
  bigint: ["historical_blocks", "blocknum"], // --blocknum 2398572498
  default: { historical_blocks: 4 },
});

const getBlockHeader = async (blockNumber: bigint | null) => {
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

const setDefaults = async () => {
  // if blocknum is null/unspecified, just latest
  if (args.blocknum === null) {
    const latestBlock = await getBlockHeader(null);
    console.log(JSON.stringify(latestBlock.data.result));
    args.blocknum = latestBlock.data.result.number;
    console.log(`set blocknum to latest ${args.blocknum}`);
  }
};

const getBlockHeaders = async (blocknum: bigint, history: bigint) => {
  let currentBlockNumber = blocknum;
  let fetched = 0;
  const blockHeaders = [];
  while (fetched < history) {
    blockHeaders.push(getBlockHeader(currentBlockNumber));
    fetched += 1;
    // @ts-ignore
    currentBlockNumber -= 1;
  }
  await Promise.all(blockHeaders);
  return blockHeaders;
};

const encodeRLP = (blockHeader: object) => {
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
  } = block.data.result;

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
  // fixed size of 112, so pad to 0s
  // and convert the hex values to integers

  // open an input_{blocknum}.json file
  // write the array of integers under the key "blockRlpHexs"

  console.log("Block Number", number);
  console.log("Mix hash", mixHash);
  console.log("Derived Block Hash", derivedBlockHash);
  console.log("Actual Block Hash", hash);
  console.log("=========================");
};

setDefaults();
const blockHeaders = getBlockHeaders(args.blocknum, args.historical_blocks);

// output: an array of RLP encoding, from oldest to newest
