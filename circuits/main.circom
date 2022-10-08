pragma circom 2.0.2;

include "./blockheader.circom";
			
// our circuit starts from a historical block and then proves
component main = EthBlockHashHex(200);
