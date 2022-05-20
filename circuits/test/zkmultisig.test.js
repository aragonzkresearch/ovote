const path = require("path");
const fs = require("fs");

const { assert, expect } = require("chai");

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
	    component main {public [chainID, processID, censusRoot, result]}= zkmultisig(2, 2);
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
	    censusRoot: 0n,
	    receiptsRoot: 0n,
	    nVotes: 0n,
	    result: 0n, // result should be 0, despite having 2 vote values, as there are no signatures & censusProofs
	    withReceipts: 1n,
	    vote: [1n, 1n],
	    index: [0n, 0n],
	    pkX: [0n, 0n],
	    pkY: [0n, 0n],
	    weight: [1n, 1n],
	    s: [0n, 0n],
	    r8x: [0n, 0n],
	    r8y: [0n, 0n],
	    siblings: [[0n, 0n, 0n], [0n, 0n, 0n]],
	    receiptsSiblings: [[0n, 0n, 0n], [0n, 0n, 0n]]
	};

	const witness = await cir.calculateWitness(inputs, true);
	await cir.checkConstraints(witness);
    });

    it ("expect error when trying to count votes without their signatures", async () => {
	const inputs = {
	    chainID: 0n,
	    processID: 0n,
	    censusRoot: 0n,
	    receiptsRoot: 0n,
	    nVotes: 0n,
	    result: 2n, // try to set result != 0, expecting the circuit to fail
	    withReceipts: 1n,
	    vote: [1n, 1n],
	    index: [0n, 0n],
	    pkX: [0n, 0n],
	    pkY: [0n, 0n],
	    weight: [1n, 1n],
	    s: [0n, 0n],
	    r8x: [0n, 0n],
	    r8y: [0n, 0n],
	    siblings: [[0n, 0n, 0n], [0n, 0n, 0n]],
	    receiptsSiblings: [[0n, 0n, 0n], [0n, 0n, 0n]]
	};

	try {
	    const witness = await cir.calculateWitness(inputs, true);
	    await cir.checkConstraints(witness);

	    // The line will only be reached if no error is thrown above
	    throw new Error(`Expected an error and didn't get one`);
	} catch(err) {
	    expect(err.message).to.contain("Error in template zkmultisig");
	}
    });

    it ("prevent votes different than 0 or 1", async () => {
	const inputs = {
	    chainID: 0n,
	    processID: 0n,
	    censusRoot: 0n,
	    receiptsRoot: 0n,
	    nVotes: 0n,
	    result: 0n,
	    withReceipts: 1n,
	    vote: [0n, 2n],
	    index: [0n, 0n],
	    pkX: [0n, 0n],
	    pkY: [0n, 0n],
	    weight: [1n, 1n],
	    s: [0n, 0n],
	    r8x: [0n, 0n],
	    r8y: [0n, 0n],
	    siblings: [[0n, 0n, 0n], [0n, 0n, 0n]],
	    receiptsSiblings: [[0n, 0n, 0n], [0n, 0n, 0n]]
	};

	try {
	    const witness = await cir.calculateWitness(inputs, true);
	    await cir.checkConstraints(witness);

	    // The line will only be reached if no error is thrown above
	    throw new Error(`Expected an error and didn't get one`);
	} catch(err) {
	    expect(err.message).to.contain("Error in template zkmultisig");
	}
    });
});

describe("BinaryCheck circuit", function () {
    this.timeout(100000);

    let cir;
    before(async () => {
	const circuitPath = path.join(__dirname, "circuits", "binaryCheck.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    template BinaryCheck() {
		signal input v;
		v * (v - 1) === 0;
	    }
	    component main {public [v]}= BinaryCheck();
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");

	cir = await wasm_tester(circuitPath);
    });

    it ("check voteValue=0", async () => {
	const inputs = {
	    v: 0n
	};

	const witness = await cir.calculateWitness(inputs, true);
	await cir.checkConstraints(witness);
    });
    it ("check voteValue=1", async () => {
	const inputs = {
	    v: 1n
	};

	const witness = await cir.calculateWitness(inputs, true);
	await cir.checkConstraints(witness);
    });
    it ("check voteValue=2, expecting an error", async () => {
	const inputs = {
	    v: 2n
	};

	try {
	    const witness = await cir.calculateWitness(inputs, true);
	    await cir.checkConstraints(witness);

	    // The line will only be reached if no error is thrown above
	    throw new Error(`Expected an error and didn't get one`);
	} catch(err) {
	    expect(err.message).to.contain("Error in template BinaryCheck");
	}
    });
});
