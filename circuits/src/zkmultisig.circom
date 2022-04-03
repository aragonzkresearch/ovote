// zkMultisig circuit.
// For LICENSE check https://github.com/aragon/zkmultisig/blob/master/LICENSE

pragma circom 2.0.0;

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
}
