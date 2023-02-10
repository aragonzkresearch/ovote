// OAV: Onchain Anonymous Voting, using the same OVOTE census
// The OAV follows a similar design done in
// https://github.com/vocdoni/zk-franchise-proof-circuit but with some
// modifications, and it is compatible to the OVOTE census data structure.
// 
// For LICENSE check https://github.com/aragonzkresearch/ovote/blob/master/LICENSE
//
// OAV circuit checks:
// - User proves that owns a key which is in the Census MerkleTree
// - User's key (which is in the Census) has signed their vote
// - User claimed nullifier is correct, which is used by the smart contract to ensure that the same user does not vote twice


pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/eddsaposeidon.circom";
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
    signal input privK; // user babyjubjub private key
    signal input index;
    signal input s;
    signal input rx;
    signal input ry;
    signal input siblings[circomNLevels];


    
    component toSign = Poseidon(3);
    toSign.inputs[0] <== chainID;
    toSign.inputs[1] <== processID;
    toSign.inputs[2] <== vote;

    component pubK = BabyPbk();
    pubK.in <== privK;

    // check vote signature
    component voteAndCharterSigVerifier = EdDSAPoseidonVerifier();
    voteAndCharterSigVerifier.enabled <== 1;
    voteAndCharterSigVerifier.Ax <== pubK.Ax;
    voteAndCharterSigVerifier.Ay <== pubK.Ay;
    voteAndCharterSigVerifier.S <== s;
    voteAndCharterSigVerifier.R8x <== rx;
    voteAndCharterSigVerifier.R8y <== ry;
    voteAndCharterSigVerifier.M <== toSign.out;

    // ensure vote is 0 or 1 (v==0 or v==1)
    vote * (vote - 1) === 0;

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
    computedNullifier.inputs[0] <== chainID;
    computedNullifier.inputs[1] <== processID;
    computedNullifier.inputs[2] <== privK;
    component checkNullifier = ForceEqualIfEnabled();
    checkNullifier.enabled <== 1;
    checkNullifier.in[0] <== computedNullifier.out;
    checkNullifier.in[1] <== nullifier;
}
