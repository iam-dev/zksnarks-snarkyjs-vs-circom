//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier, Ownable {
    uint256[] private _hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    uint256 private constant LEVELS = 3; // the number of levels in the tree

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        // Hash 1 - 8
        for (uint256 i = 0; i < 8; i++) {
            _hashes.push(0); // pushing blank leaves
        }

        // see also MerkleTree.png
        // hashes.push(PoseidonT3.poseidon([hashByIndex(0), hashByIndex(1)])); // Hash 1,2
        // hashes.push(PoseidonT3.poseidon([hashByIndex(2), hashByIndex(3)])); // Hash 3,4
        // hashes.push(PoseidonT3.poseidon([hashByIndex(4), hashByIndex(5)])); // Hash 5,6
        // hashes.push(PoseidonT3.poseidon([hashByIndex(6), hashByIndex(7)])); // Hash 7,8
        // hashes.push(PoseidonT3.poseidon([hashByIndex(8), hashByIndex(9)])); // Hash 1,2,3,4
        // hashes.push(PoseidonT3.poseidon([hashByIndex(10), hashByIndex(11)])); // Hash 5,6,7,8
        // hashes.push(PoseidonT3.poseidon([hashByIndex(12), hashByIndex(13)])); // Hash 1,2,3,4,5,6,7,8
        for (uint256 i = 0; i < 13; i++) {
            if (i % 2 == 0) {
                _hashes.push(
                    PoseidonT3.poseidon([hashByIndex(i), hashByIndex(i + 1)])
                );
            }
        }
        root = hashByIndex((14));
    }

    // return the total number of leaves in the tree
    function hashLength() public view returns (uint256) {
        return _hashes.length;
    }

    // return the hash by index
    function hashByIndex(uint256 _index) public view returns (uint256) {
        return _hashes[_index];
    }

    function hashes() public view returns (uint256[] memory) {
        return _hashes;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input);
    }

    function insertLeaf(uint256 hashedLeaf) public onlyOwner returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        uint256 n = LEVELS;
        require(index < 2 ** n, "MerkleTree: cannot insert more leaves.");
        _hashes[index] = hashedLeaf;
        uint256 position = index;
        for (uint256 i = 0; i < n; i++) {
            uint256 odd = position % 2;
            uint256 left = position - odd;
            uint256 right = position + 1 - odd;
            position = 2 ** n + (position - odd) / 2;
            _hashes[position] = PoseidonT3.poseidon(
                [_hashes[left], _hashes[right]]
            );
        }
        root = _hashes[2 ** (n + 1) - 2]; // new root after adding a leaf
        index++;
        return index - 1;
    }
}
