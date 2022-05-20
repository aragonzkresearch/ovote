// zkMultisig circuit.
// For LICENSE check https://github.com/aragon/zkmultisig/blob/master/LICENSE

pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/smt/smtverifier.circom";
include "../node_modules/circomlib/circuits/eddsaposeidon.circom";

template zkmultisig(nMaxVotes, nLevels) {
    var circomNLevels = nLevels+1;

    /////
    // public inputs
    signal input chainID; // hardcoded in contract deployment
    signal input processID; // determined by process creation
    signal input censusRoot; // determined by process creation
    signal input receiptsRoot;
    signal input nVotes; // determined by results publishing in the contract
    signal input result; // input from the contract call
    signal input withReceipts; // input from the contract call, can be 0 or 1, indicates if the process uses receipts

    /////
    // private inputs (sorted by index)
    signal input vote[nMaxVotes];
    // user's key related
    signal input index[nMaxVotes];
    signal input pkX[nMaxVotes];
    signal input pkY[nMaxVotes];
    signal input weight[nMaxVotes];
    // signatures
    signal input s[nMaxVotes];
    signal input r8x[nMaxVotes];
    signal input r8y[nMaxVotes];
    // census proofs
    signal input siblings[nMaxVotes][circomNLevels];
    signal input receiptsSiblings[nMaxVotes][circomNLevels];

    // CensusProof verification
    component inNVotes[nMaxVotes];
    component indexChecker[nMaxVotes];
    component pkHash[nMaxVotes];
    component censusProofCheck[nMaxVotes];
    component receiptsCheck[nMaxVotes];
    component msgToSign[nMaxVotes];
    component sigVerifier[nMaxVotes];
    component validVote[nMaxVotes];

    signal voteByWeight[nMaxVotes];
    signal r[nMaxVotes+1];
    r[0] <== 0;

    // check that withReceipts is a binary value
    withReceipts * (withReceipts - 1) === 0;

    for (var i=0; i<nMaxVotes; i++) {
	// if inNVotes = i<nVotes, do the signature + censusproof verifications
	// and count the vote
	inNVotes[i] = LessThan(64); // nVotes is a uint64
	inNVotes[i].in[0] <== i;
	inNVotes[i].in[1] <== nVotes;

	// check that index[i-1]<index[i], to ensure that no pubK index is
	// repeated
	if (i>0) {
	    // TODO WIP
	    indexChecker[i] = LessThan(64); // index is a uint64
	    indexChecker[i].in[0] <== index[i-1];
	    indexChecker[i].in[1] <== index[i];
	    indexChecker[i].out === 1 * inNVotes[i].out; // enable the indexChecker if i<nVotes
	}

	// check CensusProof
	pkHash[i] = Poseidon(3);
	pkHash[i].inputs[0] <== pkX[i];
	pkHash[i].inputs[1] <== pkY[i];
	pkHash[i].inputs[2] <== weight[i];
	
	censusProofCheck[i] = SMTVerifier(circomNLevels);
	censusProofCheck[i].enabled <== inNVotes[i].out; // enable it if i<nVotes
	censusProofCheck[i].fnc <== 0; // 0 as is to verify inclusion
	censusProofCheck[i].root <== censusRoot;
	for (var j=0; j<circomNLevels; j++) {
	    censusProofCheck[i].siblings[j] <== siblings[i][j];
	}
	censusProofCheck[i].oldKey <== 0;
	censusProofCheck[i].oldValue <== 0;
	censusProofCheck[i].isOld0 <== 0;
	censusProofCheck[i].key <== index[i];
	censusProofCheck[i].value <== pkHash[i].out;

	// check receipts proof
	receiptsCheck[i] = SMTVerifier(circomNLevels);
	receiptsCheck[i].enabled <== inNVotes[i].out * withReceipts; // enable it if i<nVotes & withReceipts==true
	receiptsCheck[i].fnc <== 0; // 0 as is to verify inclusion
	receiptsCheck[i].root <== receiptsRoot;
	for (var j=0; j<circomNLevels; j++) {
	    receiptsCheck[i].siblings[j] <== receiptsSiblings[i][j];
	}
	receiptsCheck[i].oldKey <== 0;
	receiptsCheck[i].oldValue <== 0;
	receiptsCheck[i].isOld0 <== 0;
	receiptsCheck[i].key <== index[i];
	receiptsCheck[i].value <== pkHash[i].out;


	// check signature
	msgToSign[i] = Poseidon(3);
	msgToSign[i].inputs[0] <== chainID;
	msgToSign[i].inputs[1] <== processID;
	msgToSign[i].inputs[2] <== vote[i];
	
	sigVerifier[i] = EdDSAPoseidonVerifier();
	sigVerifier[i].enabled <== inNVotes[i].out; // enable it if i<nvotes
	sigVerifier[i].Ax <== pkX[i];
	sigVerifier[i].Ay <== pkY[i];
	sigVerifier[i].S <== s[i];
	sigVerifier[i].R8x <== r8x[i];
	sigVerifier[i].R8y <== r8y[i];
	sigVerifier[i].M <== msgToSign[i].out;

	// ensure vote is 0 or 1 (v==0 or v==1)
	vote[i] * (vote[i] - 1) === 0;

	// count the vote (if i<nVotes)
	voteByWeight[i] <== vote[i] * weight[i];
	r[i+1] <== r[i] + voteByWeight[i] * inNVotes[i].out;
    }

    // check result
    result === r[nMaxVotes];
}
