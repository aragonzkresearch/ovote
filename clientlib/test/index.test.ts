const path = require("path");
const wasm_tester = require("circom_tester").wasm;

const { buildEddsa, buildPoseidon } = require("circomlibjs");
const { Client, Voter } = require("../src/index");

export {};

describe("full vote process flow (interacting with ovote-node)", function () {
	this.timeout(100000);

	it("flow", async () => {
		const chainID = 42;
		const poseidon = await buildPoseidon();

		const client = await Client.new(chainID);


		// new voter keys
		let voters = [];
		for ( let i = 0; i < 16; i++ ) {
			const sk = poseidon.F.e(i);
			// console.log("sk (value)", poseidon.F.toObject(sk).toString());
			const v = client.newVoter(sk);
			// alternatively:
			// const v = new Voter(client, sk);
			voters.push(v);
		}
		console.log(voters[0]);

		// WIP:
		// create a list of publicKeys
		// send the publicKeys to the ovote-node to create a census
		// close the census
		// get the CensusRoot for the census
		// publish new process using that CensusRoot
		// users retrieve their CensusProofs
		// users sign their votes
		// users send {CensusProof + Signature + Vote} to the ovote-node
		// 	if accepted, everything should be fine
	});
});

