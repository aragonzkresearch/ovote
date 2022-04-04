// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// WARNING: This code is WIP, in early stages.

contract ZKMultisig {
	struct Process {
		address creator; // the sender of the tx that created the process
		uint256 censusRoot;
		// next 6 values use 209 bits, so they fit in a single 256 storage slot
		uint64 censusSize;
		uint64 ethEndBlockNum;
		uint64 resultsPublishingWindow;
		uint8 minParticipation;
		uint8 minPositiveVotes;
		bool closed;
	}

	uint256 public lastProcessID; // initialized at 0
	mapping(uint256 => Process) public processes;

	// newProcess stores Process struct into the processes mapping
	function newProcess(
		uint256 censusRoot,
		uint64 censusSize,
		uint64 ethEndBlockNum,
		uint64 resultsPublichingWindow,
		uint8 minParticipation,
		uint8 minPositiveVotes
	) public returns (uint256) {
		require(minPositiveVotes <= censusSize, "minPositiveVotes <= censusSize");

		processes[lastProcessID +1] = Process(msg.sender, censusRoot,
				  censusSize, ethEndBlockNum,
				  resultsPublichingWindow, minParticipation,
				  minPositiveVotes, false);

		// assume that we use solidity>=0.8, which prevents overflow with normal addition
		lastProcessID += 1;

		return lastProcessID;
	}
}
