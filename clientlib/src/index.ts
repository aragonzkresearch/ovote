import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from "axios";
const { buildEddsa, buildPoseidon } = require("circomlibjs");

const fromHexString = hexString =>
	new Uint8Array(hexString.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));

const toHexString = bytes =>
	bytes.reduce((str, byte) => str + byte.toString(16).padStart(2, '0'), '');

// key creation, iteration 0 is creating a new privK, for the 1st iteration
// private key will be derived from a Metamask (secp256k1) signature, as other
// zkRollups do

class Client {
	poseidon: any;
	F: any;
	eddsa: any;

	chainID: number;
	url: string; // zkmultisig-node url

	// using the 'static async new' approach (instead of 'constructor'), in
	// order to be able to do an async constructor of the Client class
	static async new(chainID: number) {
		let c = new Client();
		c.poseidon = await buildPoseidon();
		c.F = c.poseidon.F;
		c.eddsa = await buildEddsa();
		c.chainID = chainID;
		return c;
	}

	newVoter(sk: Uint8Array) {
		return new Voter(this, sk);
	}
}

class Voter {
	sk: Uint8Array;
	pk: string;
	pkComp: Uint8Array;

	poseidon: any;
	F: any;
	eddsa: any;

	// constructor(poseidon: any, eddsa: any, sk: Uint8Array) {
	// constructor(sk: Uint8Array) {
	constructor(client: Client, sk: Uint8Array) {
		// using the 'static async new' approach, in order to be able
		// to do an async constructor of the Voter class
		this.poseidon = client.poseidon;
		this.F = client.F;
		this.eddsa = client.eddsa;

		this.sk = sk;
		this.pk = this.eddsa.prv2pub(sk);
		this.pkComp = this.eddsa.babyJub.packPoint(this.pk);
	}

	newVotePackage(chainID, processID, index, merkleProof, vote) {
		// sign the vote
		const toSign = this.poseidon([chainID, processID, vote]);
		const sig = this.eddsa.signPoseidon(this.sk, toSign);
		const sigComp = this.eddsa.packSignature(sig);


		const votePackage = {
			signature: toHexString(sigComp),
			censusProof: {
				index: index,
				publicKey: toHexString(this.pkComp),
				merkleProof: merkleProof,
			},
			vote: vote
		};
		return votePackage;
	}
}

module.exports = {
	Client,
	Voter
}
