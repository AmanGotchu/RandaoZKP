// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import "./BlockHashRegistry.sol";

error Overallocated();
error RandomnessNotFound();

contract StochasticFaucet {
    using SafeTransferLib for address;
    BlockHashRegistry public immutable registry;

    struct Bet {
        uint256 batchNum;
        uint256 betSize;
    }

    event BetSettled();
    event RngRequested(address entrant, uint256 desiredBlock);

    mapping(address => Bet) public bets;
    mapping(uint256 => uint256) public batchToTotalBet;
    uint256 public allocated = 0;

    uint256 public constant BATCH_INTERVAL_SIZE = 100;

    constructor(BlockHashRegistry _registry) {
        registry = _registry;
    }

    function getBatchBlock() public view returns (uint256 batchBlock) {
        uint256 offset = block.number % BATCH_INTERVAL_SIZE;
        batchBlock = block.number - offset + BATCH_INTERVAL_SIZE;
    }

    function bet() public payable {
        if (bets[msg.sender].batchNum != 0) {
            settle(msg.sender);
        }
        allocated += msg.value;
        if (allocated > address(this).balance) {
            revert Overallocated();
        }
        uint256 batchBlockNum = getBatchBlock();
        emit RngRequested(msg.sender, batchBlockNum);
        bets[msg.sender] = Bet(batchBlockNum, msg.value);
        batchToTotalBet[batchBlockNum] += msg.value;
    }

    function settle(address entrant) public {
        Bet memory bet = bets[entrant];
        bytes32 rand = registry.numToRandMix(bet.batchNum);
        if (rand == bytes32(0)) {
            revert RandomnessNotFound();
        }
        uint256 roll = uint256(rand) % 64;
        // Entrant has a slight edge.
        if (roll >= 31) {
            // Entrant address won
            allocated -= bet.betSize;
            entrant.safeTransferETH(bet.betSize);
        } else {
            // Entrant (and everyone else in this batch) lost.
            allocated -= batchToTotalBet[bet.batchNum];
            delete batchToTotalBet[bet.batchNum];
        }
        emit BetSettled();
        delete bets[entrant];
    }

    receive() external payable {}
}
