#!/bin/bash
 
cd circuits

mkdir Poseidon

if [ -f ./powersOfTau28_hez_final_10.ptau ]; then
    echo "powersOfTau28_hez_final_10.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_10.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau
fi

echo "Compiling poseidon circuit.circom..."

# compile circuit

circom poseidonTest.circom --r1cs --wasm --sym -o Poseidon
snarkjs r1cs info Poseidon/poseidonTest.r1cs

# Start a new zkey and make a contribution

snarkjs groth16 setup Poseidon/poseidonTest.r1cs powersOfTau28_hez_final_10.ptau Poseidon/poseidonTest_0000.zkey
snarkjs zkey contribute Poseidon/poseidonTest_0000.zkey Poseidon/poseidonTest.zkey --name="1st Contributor Name" -v -e="random text"
snarkjs zkey export verificationkey Poseidon/poseidonTest.zkey Poseidon/verification_key.json

# generate solidity contract
snarkjs zkey export solidityverifier Poseidon/poseidonTest.zkey ../contracts/PoseidonTest.sol

cd ..