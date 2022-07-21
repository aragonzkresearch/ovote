// OAV: Onchain Anonymous Voting, using the same OVOTE census
// The OAV follows the same design done in
// https://github.com/vocdoni/zk-franchise-proof-circuit but adapted to the
// OVOTE census data structure.
// 
// For LICENSE check https://github.com/aragonzkresearch/ovote/blob/master/LICENSE

pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/smt/smtverifier.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";


// OAV: Onchain Anonymous Voting
template oav(nLevels) {
    var circomNLevels = nLevels+1;

    /////
    // public inputs
    signal input chainID; // hardcoded in contract deployment
    signal input processID; // determined by process creation
    signal input censusRoot; // determined by process creation
    signal input weight;
    signal input nullifier;
    signal input vote;

    /////
    // private inputs
    signal input index;
    signal input privateKey;
    signal input siblings[circomNLevels];

    component pubK = BabyPbk();
    pubK.in <== privateKey;

    // check CensusProof
    component pkHash = Poseidon(3);
    pkHash.inputs[0] <== pubK.Ax;
    pkHash.inputs[1] <== pubK.Ay;
    pkHash.inputs[2] <== weight;
    
    component censusProofCheck = SMTVerifier(circomNLevels);
    censusProofCheck.enabled <== 1;
    censusProofCheck.fnc <== 0; // 0 as is to verify inclusion
    censusProofCheck.root <== censusRoot;
    for (var i=0; i<circomNLevels; i++) {
	censusProofCheck.siblings[i] <== siblings[i];
    }
    censusProofCheck.oldKey <== 0;
    censusProofCheck.oldValue <== 0;
    censusProofCheck.isOld0 <== 0;
    censusProofCheck.key <== index;
    censusProofCheck.value <== pkHash.out;

    // check nullifier
    component computedNullifier = Poseidon(3);
    computedNullifier.inputs[0] <== privateKey;
    computedNullifier.inputs[1] <== chainID;
    computedNullifier.inputs[2] <== processID;
    component checkNullifier = ForceEqualIfEnabled();
    checkNullifier.enabled <== 1;
    checkNullifier.in[0] <== computedNullifier.out;
    checkNullifier.in[1] <== nullifier;
}
