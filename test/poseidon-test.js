const chai = require('chai');
const { resolve } = require('path');
const F1Field = require('ffjavascript').F1Field;
const Scalar = require('ffjavascript').Scalar;
exports.p = Scalar.fromString(
  '21888242871839275222246405745257275088548364400416034343698204186575808495617',
);
const Fr = new F1Field(exports.p);

const wasm_tester = require('circom_tester').wasm;
const buildPoseidon = require('circomlibjs').buildPoseidon;

const assert = chai.assert;

describe("PoseidonHash", function () {
  let poseidon, F;

  before(async () => {
    poseidon = await buildPoseidon();
    F = poseidon.F;
  });
  it('Should test circuit', async () => {
    const circuit = await wasm_tester(
      resolve('./circuits/poseidonTest.circom'),
    );

    const res = poseidon([7777777, 1]);
    const INPUT = {
      "inputs" : [7777777, 1],
  }
    console.log('res',res );
    let witness = await circuit.calculateWitness(
      INPUT,
      true,
    );
    console.log('witness',witness );

    assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
    assert(F.eq(F.e(witness[1]), F.e(res)));
    await circuit.assertOut(witness, { out: F.toObject(res) });
    await circuit.checkConstraints(witness);

  });
  it("Should check wrong guessess", async () => {
    const circuit = await wasm_tester(
      resolve('./circuits/poseidonTest.circom'),
    );

    const privSalt = Math.floor(Math.random()*10**10);

    const INPUT = {
        "inputs" : [privSalt, 1],
    }

    const witness = await circuit.calculateWitness(INPUT, true);

    assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
  });
});