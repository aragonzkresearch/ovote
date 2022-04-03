const path = require("path");
const fs = require("fs");

const chai = require("chai");
const assert = chai.assert;

// const c_tester = require("circom_tester").c;
const wasm_tester = require("circom_tester").wasm;


describe("zkmultisig 4 votes, 2 lvls", function () {
    this.timeout(100000);

    let cir;
    before(async () => {
	const circuitPath = path.join(__dirname, "circuits", "4votes2lvls.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    include "../../src/zkmultisig.circom";
	    component main {public [chainID, processID, ethEndBlockNum, censusRoot, result]}= zkmultisig(4, 2);
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");

	// cir = await c_tester(circuitPath);
	cir = await wasm_tester(circuitPath);

	await cir.loadConstraints();
	console.log("n_constraints", cir.constraints.length);
    });

    it ("circuit test", async () => {
	// WIP
	const inputs = {};

	const witness = await cir.calculateWitness(inputs, true);

	// const stateOut = witness.slice(1, 1+(32*8));
	// assert.deepEqual(stateOutBytes, expectedOut);
    });
});
