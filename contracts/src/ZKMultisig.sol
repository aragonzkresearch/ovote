// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// WARNING: This code is WIP, in early stages.

/// @title ZKMultisig
contract ZKMultisig {
	struct Process {
		address creator; // the sender of the tx that created the process
		uint256 transactionHash;
		uint256 censusRoot;

		// next 6 values use 209 bits, so they fit in a single 256 storage slot
		uint64 censusSize;
		uint64 ethEndBlockNum;
		uint64 resultsPublishingWindow;
		uint8 minParticipation;
		uint8 minPositiveVotes;
		bool closed;
	}
	struct Result {
		address publisher;
		uint256 result;
		uint256 nVotes;
	}

	uint256 public lastProcessID; // initialized at 0
	mapping(uint256 => Process) public processes;
	mapping(uint256 => Result) public results;

	event EventProcessCreated(address creator, uint256 id,uint256
				  transactionHash,  uint256 censusRoot, uint64
				  censusSize, uint64 ethEndBlockNum, uint64
				  resultsPublichingWindow, uint8
				  minParticipation, uint8 minPositiveVotes);
	event EventProcessClosed(address caller, uint256 id, bool success);


	// @notice stores a new Process into the processes mapping
	function newProcess(
		uint256 transactionHash,
		uint256 censusRoot,
		uint64 censusSize,
		uint64 ethEndBlockNum,
		uint64 resultsPublichingWindow,
		uint8 minParticipation,
		uint8 minPositiveVotes
	) public returns (uint256) {
		require(minPositiveVotes <= censusSize, "minPositiveVotes <= censusSize");

		processes[lastProcessID +1] = Process(msg.sender, transactionHash,
				censusRoot, censusSize, ethEndBlockNum,
				resultsPublichingWindow, minParticipation,
				minPositiveVotes, false);

		// assume that we use solidity versiont >=0.8, which prevents
		// overflow with normal addition
		lastProcessID += 1;

		emit EventProcessCreated(msg.sender, lastProcessID, transactionHash,
					 censusRoot, censusSize, ethEndBlockNum,
					 resultsPublichingWindow,
					 minParticipation, minPositiveVotes);

		return lastProcessID;
	}

	// @notice closes the process for the given id
	function closeProcess(uint256 id) public {
		// get process by id
		Process storage process = processes[id];
		require(process.closed == false, "process already closed");

		// close process (in storage)
		process.closed = true;


		// get result by process id
		Result storage result;
		result = results[id];

		// minParticipationNumber =  // TODO % of minParticipation & minPositiveVotes

		require(block.number >= process.ethEndBlockNum + process.resultsPublishingWindow,
			"process.ethEndBlockNum not reached yet");
		if (result.result >= process.minPositiveVotes) {
			// TODO call the tx of the transactionHash
		}

		emit EventProcessClosed(msg.sender, id, true);
	} 
}
