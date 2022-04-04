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
    signal input ethEndBlockNum; // determined by process creation
    signal input censusRoot; // determined by process creation
    signal input nVotes; // determined by results publishing in the contract
    signal input result; // input from the contract call

    /////
    // private inputs (sorted by index)
    signal input vote[nMaxVotes];
    // user's key related
    signal input index[nMaxVotes];
    signal input pkX[nMaxVotes];
    signal input pkY[nMaxVotes];
    // signatures
    signal input s[nMaxVotes];
    signal input r8x[nMaxVotes];
    signal input r8y[nMaxVotes];
    // census proofs
    signal input siblings[nMaxVotes][circomNLevels];

    // CensusProof verification
    component inNVotes[nMaxVotes];
    component indexChecker[nMaxVotes];
    component pkHash[nMaxVotes];
    component smtPkExists[nMaxVotes];
    component msgToSign[nMaxVotes];
    component sigVerifier[nMaxVotes];

    // TODO check nVotes <= nMaxVotes

    signal r[nMaxVotes+1];
    r[0] <== 0;

    for (var i=0; i<nMaxVotes; i++) {
	// inNVotes = i<nVotes
	inNVotes[i] = LessThan(32);
	inNVotes[i].in[0] <== i;
	inNVotes[i].in[1] <== nVotes;

	// check that index[i]<index[i+1], to ensure that no pubK index is
	// repeated
	if (i<nMaxVotes-1) { // TODO make it depend on i<nVotes-1
	    indexChecker[i] = LessThan(32);
	    indexChecker[i].in[0] <== index[i];
	    indexChecker[i].in[1] <== index[i+1];
	    indexChecker[i].out === 1 * inNVotes[i].out ; // enable the indexChecker if i<nVotes
	}


	// check CensusProof
	pkHash[i] = Poseidon(2);
	pkHash[i].inputs[0] <== pkX[i];
	pkHash[i].inputs[1] <== pkY[i];
	
	smtPkExists[i] = SMTVerifier(circomNLevels);
	smtPkExists[i].enabled <== inNVotes[i].out; // enable it if i<nVotes
	smtPkExists[i].fnc <== 0; // 0 as is to verify inclusion
	smtPkExists[i].root <== censusRoot;
	for (var j=0; j<circomNLevels; j++) {
	    smtPkExists[i].siblings[j] <== siblings[i][j];
	}
	smtPkExists[i].oldKey <== 0;
	smtPkExists[i].oldValue <== 0;
	smtPkExists[i].isOld0 <== 0;
	smtPkExists[i].key <== index[i];
	smtPkExists[i].value <== pkHash[i].out;


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

	// TODO ensure vote is 0 or 1

	// count the vote (if i<nVotes)
	r[i+1] <== r[i] + vote[i] * inNVotes[i].out;
    }
    // check result
    result === r[nMaxVotes];
}
