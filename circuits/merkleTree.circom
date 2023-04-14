pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

include "./poseidonHashSwitcher.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;
    

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var numLeafHashers = leaves / 2;
    // this will be used to hash the output of the leaf hasher components
    var numIntHashers = numLeafHashers - 1;

    var numHashers = leaves - 1;
    component hashers[numHashers];

    for (var i=0; i < numHashers; i++) {
        hashers[i] = PoseidonHashSwitcher();
    }

    for (var i = 0; i < numLeafHashers; i++){
        hashers[i].left <== leaves[i*2];
        hashers[i].right <== leaves[i*2+1];
    }

    var k = 0;
    for (var i = numLeafHashers; i < numLeafHashers + numIntHashers; i++) {
        hashers[i].left <== hashers[k*2].hash;
        hashers[i].right <== hashers[k*2+1].hash;
        k++;
    }

    // Constraints.  
    root <== hashers[numHashers-1].hash;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashers[n];
    component mux[n];

    signal levelHashes[n + 1];
    levelHashes[0] <== leaf;

    for (var i = 0; i < n; i++) {
        // Should be 0 or 1
        path_index[i] * (1 - path_index[i]) === 0;

        hashers[i] = PoseidonHashSwitcher();
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== levelHashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== levelHashes[i];

        mux[i].s <== path_index[i];
        hashers[i].left <== mux[i].out[0];
        hashers[i].right <== mux[i].out[1];

        levelHashes[i + 1] <== hashers[i].hash;
    }

    root <== levelHashes[n];
}