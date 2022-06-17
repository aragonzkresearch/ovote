// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

// OVOTE contract.
// For LICENSE check https://github.com/groupoidlabs/ovote/blob/master/LICENSE

// WARNING: This code is WIP, in early stages.

/// @title OVOTE
/// @author Groupoid Labs - 2022
contract OVOTE {
	struct Process {
		address creator; // the sender of the tx that created the process
		uint256 transactionHash;
		uint256 censusRoot;

		// next 7 values are grouped and they use 217 bits, so they fit
		// in a single 256 storage slot
		uint64 censusSize;
		uint64 resPubStartBlock; // results publishing start block
		uint64 resPubWindow; // results publishing window
		uint8 minParticipation; // number of votes
		uint8 minPositiveVotes; // % over nVotes
		uint8 typ; // type of process, 0: multisig, 1: referendum
		bool closed;
	}
	struct Result {
		address publisher;
		uint256 receiptsRoot;
		uint64 result;
		uint64 nVotes;
	}

	uint256 public lastProcessID; // initialized at 0
	// TODO change Process ID to uint64
	mapping(uint256 => Process) public processes;
	mapping(uint256 => Result) public results;


	// Events used to synchronize the ovote-node when scanning the blocks

	event EventProcessCreated(address creator, uint256 id, uint256
				  transactionHash,  uint256 censusRoot, uint64
				  censusSize, uint64 resPubStartBlock, uint64
				  resPubWindow, uint8 minParticipation, uint8
				  minPositiveVotes,  uint8 typ);

	event EventResultPublished(address publisher, uint256 id, uint256
				   receiptsRoot, uint64 result, uint64 nVotes);

	event EventProcessClosed(address caller, uint256 id, bool success);


	/// @notice stores a new Process into the processes mapping
	/// @param transactionHash keccak256 hash of the transaction that will be executed if the process succeeds
	/// @param censusRoot MerkleRoot of the CensusTree used for the process, which will be used to verify the zkSNARK proofs of the results
	/// @param censusSize Number of leaves in the CensusTree used for the process
	/// @param resPubStartBlock Block number where the results publishing phase starts
	/// @param resPubWindow Window of time (in number of blocks) of the results publishing phase
	/// @param minParticipation Threshold of minimum number of votes over the total users in the census (over CensusSize)
	/// @param minPositiveVotes Threshold of minimum votes supporting the proposal, over all the processed votes (% over nVotes)
	/// @return id assigned to the created process
	function newProcess(
		uint256 transactionHash,
		uint256 censusRoot,
		uint64 censusSize,
		uint64 resPubStartBlock,
		uint64 resPubWindow,
		uint8 minParticipation,
		uint8 minPositiveVotes,
		uint8 typ
	) public returns (uint256) {
		require(typ<=1, "typ must be 0 or 1");
		require(minPositiveVotes <= 100, "minPositiveVotes <= 100");

		if (typ==0) {
			// we're in multisig mode, nullify the referendum exclusive params
			resPubWindow = 0;
			minPositiveVotes = 0;
		}

		processes[lastProcessID +1] = Process(msg.sender, transactionHash,
				censusRoot, censusSize, resPubStartBlock, resPubWindow,
				minParticipation,minPositiveVotes, typ, false);

		// assume that we use solidity versiont >=0.8, which prevents
		// overflow with normal addition
		lastProcessID += 1;

		emit EventProcessCreated(msg.sender, lastProcessID, transactionHash,
					 censusRoot, censusSize, resPubStartBlock,
					 resPubWindow, minParticipation,
					 minPositiveVotes, typ);

		return lastProcessID;
	}

	/// @notice validates the proposed result during the results-publishing
	/// phase, and if it is valid, it stores it for the process id
	/// @param id Process id
	/// @param receiptsRoot The MerkleRoot of the tree built from of included voters
	/// @param result The proposed result
	/// @param nVotes The number of votes included in the result
	// /// @param a Groth16 proof G1 point
	// /// @param b Groth16 proof G2 point
	// /// @param c Groth16 proof G1 point
	function publishResult(uint256 id,
		uint256 receiptsRoot,
		uint64 result,
		uint64 nVotes
		// uint[2] memory a, uint[2][2] memory b, uint[2] memory c // WIP Groth16 proof
        ) public {
		// check that id has a process
		require(id<=lastProcessID, "process id does not exist");

		Process storage process = processes[id];
		require(process.closed == false, "process already closed");

		// check that resPubStartBlock has been reached
		require(block.number >= processes[id].resPubStartBlock,
			"nVotes >= process.resPubStartBlock");

		if (process.typ==1) { // referendum type
			// check that ResultsPublishingWindow is not over
			require(block.number < processes[id].resPubStartBlock + processes[id].resPubWindow,
				"nVotes < process.resPubStartBlock + process.resPubWindow");
		}

		// check that nVotes <= process.censusSize
		require(nVotes <= processes[id].censusSize,
			"nVotes <= processes[id].censusSize");

		// TODO build inputs array (using Process parameters from processes mapping)
		// TODO call zkProof verification


		// note: for the moment the next checks are done in the contract
		require(nVotes <= process.censusSize,
			"nVotes <= process.censusSize");
		require(nVotes > process.minParticipation, // TODO use % of minParticipation over censusSize
			"nVotes > process.minParticipation %");


		if (process.typ==1) { // referendum type
			require(nVotes > results[id].nVotes,
				"nVotes > results[id].nVotes");

			// Result memory result;
			results[id] = Result(msg.sender, receiptsRoot, result, nVotes);
		}

		emit EventResultPublished(msg.sender, id, receiptsRoot, result, nVotes);

		if (process.typ==0) {
			process.closed = true;
			emit EventProcessClosed(msg.sender, id, true);
			// TODO call the tx of the transactionHash
		}
	}

	// @notice closes the process for the given id
	// @param id Process id
	function closeProcess(uint256 id) public {
		// get process by id
		Process storage process = processes[id];

		require(process.closed == false, "process already closed");
		require(process.typ == 1, "can not close multisig type, is closed through publishResult call");

		// get result by process id
		Result storage result;
		result = results[id];

		require(block.number >= process.resPubStartBlock + process.resPubWindow,
			"process.resPubStartBlock not reached yet");
		if (result.result >= process.minPositiveVotes) { // TODO use % of minPositiveVotes over nVotes
			// TODO call the tx of the transactionHash
		}

		// close process (in storage)
		process.closed = true;

		emit EventProcessClosed(msg.sender, id, true);
	} 
}
