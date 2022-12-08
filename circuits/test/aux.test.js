const path = require("path");
const fs = require("fs");

const chai = require("chai");
const assert = chai.assert;

const wasm_tester = require("circom_tester").wasm;

// Aux tests to check n_constraints depending on the circuit design

describe("Check nConstraints for PkXExtractor vs poseidon hash", function () {
    this.timeout(100000);

    let cir;
    it ("PkXExtractor", async () => {
	const circuitPath = path.join(__dirname, "circuits", "pkxextractor.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    include "../../node_modules/circomlib/circuits/pointbits.circom";
	    template PkXExtractor(){
		signal input sign;
		signal input y;
		signal output x;
		component n2bY = Num2Bits(254);
		n2bY.in <== y;
		component b2Point = Bits2Point_Strict();
		var i;
		for (i = 0; i < 254; i++) {
		    b2Point.in[i] <== n2bY.out[i];
		}
		b2Point.in[254] <== 0;
		b2Point.in[255] <== sign;
		b2Point.out[0] ==> x;
	    }
	    component main = PkXExtractor();
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");
    
	cir = await wasm_tester(circuitPath);
    
	await cir.loadConstraints();
	console.log("PkXExtractor n_constraints", cir.constraints.length);
    });
    
    it ("PoseidonHash", async () => {
	const circuitPath = path.join(__dirname, "circuits", "poseidon2.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    include "../../node_modules/circomlib/circuits/poseidon.circom";
	    component main = Poseidon(2);
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");
    
	cir = await wasm_tester(circuitPath);
    
	await cir.loadConstraints();
	console.log("Poseidon n_constraints", cir.constraints.length);
    });

    it ("NullifierCheck", async () => {
	const circuitPath = path.join(__dirname, "circuits", "nullifiercheck.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    include "../../node_modules/circomlib/circuits/poseidon.circom";
	    include "../../node_modules/circomlib/circuits/comparators.circom";

	    template NullifierCheck() {
		    signal input chainID; // public
		    signal input processID; // public
		    signal input nullifier; // public
		signal input secretKey;

		component computedNullifier = Poseidon(3);
		computedNullifier.inputs[0] <== secretKey;
		computedNullifier.inputs[1] <== chainID;
		computedNullifier.inputs[2] <== processID;
		component checkNullifier = ForceEqualIfEnabled();
		checkNullifier.enabled <== 1;
		checkNullifier.in[0] <== computedNullifier.out;
		checkNullifier.in[1] <== nullifier;
	    }

	    component main = NullifierCheck();
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");

	cir = await wasm_tester(circuitPath);

	await cir.loadConstraints();
	console.log("NullifierCheck n_constraints", cir.constraints.length);
    });

    it ("IndexCheck", async () => {
	const circuitPath = path.join(__dirname, "circuits", "indexcheck.circom");
	const circuitCode = `
	    pragma circom 2.0.0;
	    include "../../node_modules/circomlib/circuits/comparators.circom";

	    template IndexCheck() {
		signal input index0;
		signal input index1;

		component indexChecker = LessThan(64); // index is a uint64
		indexChecker.in[0] <== index0;
		indexChecker.in[1] <== index1;
		indexChecker.out === 1;
	    }

	    component main = IndexCheck();
	`;
	fs.writeFileSync(circuitPath, circuitCode, "utf8");

	cir = await wasm_tester(circuitPath);

	await cir.loadConstraints();
	console.log("IndexCheck n_constraints", cir.constraints.length);
    });
});
