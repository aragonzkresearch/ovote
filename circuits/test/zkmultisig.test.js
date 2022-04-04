const path = require("path");
const fs = require("fs");

const chai = require("chai");
const assert = chai.assert;

// const c_tester = require("circom_tester").c;
const wasm_tester = require("circom_tester").wasm;


describe("zkmultisig 2 votes, 2 lvls", function () {
    this.timeout(100000);

    let cir;
    before(async () => {
	const circuitPath = path.join(__dirname, "circuits", "2votes2lvls.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    include "../../src/zkmultisig.circom";
	    component main {public [chainID, processID, ethEndBlockNum, censusRoot, result]}= zkmultisig(2, 2);
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");

	// cir = await c_tester(circuitPath);
	cir = await wasm_tester(circuitPath);

	await cir.loadConstraints();
	console.log("n_constraints", cir.constraints.length);
    });

    it ("prevent counting votes that don't have signature & censusProof", async () => {
	const inputs = {
	    chainID: 0n,
	    processID: 0n,
	    ethEndBlockNum: 0n,
	    censusRoot: 0n,
	    nVotes: 0n,
	    result: 0n, // result should be 0, despite having 2 vote values, as there are no signatures & censusProofs
	    vote: [1n, 1n],
	    index: [0n, 0n],
	    pkX: [0n, 0n],
	    pkY: [0n, 0n],
	    s: [0n, 0n],
	    r8x: [0n, 0n],
	    r8y: [0n, 0n],
	    siblings: [[0n, 0n, 0n], [0n, 0n, 0n]]
	};

	const witness = await cir.calculateWitness(inputs, true);
	await cir.checkConstraints(witness);
    });
});
