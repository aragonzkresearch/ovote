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
    component indexChecker[nMaxVotes];
    component pkHash[nMaxVotes];
    component smtPkExists[nMaxVotes];
    component msgToSign[nMaxVotes];
    component sigVerifier[nMaxVotes];

    for (var i=0; i<nMaxVotes; i++) {
	// check CensusProof
	pkHash[i] = Poseidon(2);
	pkHash[i].inputs[0] <== pkX[i];
	pkHash[i].inputs[1] <== pkY[i];

	smtPkExists[i] = SMTVerifier(circomNLevels);
	smtPkExists[i].enabled <== 1;
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
    }
}
