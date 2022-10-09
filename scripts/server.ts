import { poke, triggerProofSubmission } from "./triggerProofSubmission";
import * as dotenv from 'dotenv'

const express = require('express')
const app = express()
const port = 8080

app.get('/generateProof', async (req: any, res: any) => {
  dotenv.config({path: "../.env"});

  console.log("Generating proof!");

  try {
    // console.log("Poking block");
    // const tx = await poke();
    // const existingBlockNumber = tx.blockNumber;
    // console.log("Block number poked", tx.blockNumber);

    const blockToProve = 77395932;
    console.log(`Generating prove for block ${blockToProve}`)
    await triggerProofSubmission(blockToProve);

    res.status(200).send(`Successfully proved block ${blockToProve}`)
  } catch (err) {
    console.error("Generating proof failed!");
    console.error(err);

    res.status(400).send("Error generating proof!");
  }
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
