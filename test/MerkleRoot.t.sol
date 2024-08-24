// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {Merkle} from "murky/src/Merkle.sol";

contract MerkleRoot is Test {
    // variable for holding an instance of our Whitelist contract
    Whitelist whitelist;
    Merkle m;

    uint8 public constant LENGTH = 6;
    uint64 public constant VALUE = 2;
    bytes32[] private list = new bytes32[](LENGTH);

    bytes32 root;

    function setUp() public {
        m = new Merkle();
        

        // generate the merkle tree and compute its root
        root = _generateRoot(LENGTH);
        console2.log("Root: ", uint256(root));
        // deploy the whitelist contract
        whitelist = new Whitelist(root);

    }

    function testValidAddresses() public {
        for(uint8 i = 0; i < LENGTH; i++) {
            // get proof for the value at index "i" in the list
            bytes32[] memory proof = m.getProof(list, i);

            // Impersonate the current address being tested
            // This is done because our contract uses `msg.sender` as the 'original value' for
            // the address when verifying the Merkle Proof
            vm.prank(vm.addr(i + 1));

            // Check that the contract can verify the presence of this address
            // in the Merkle Tree using just the Root provided to it
            // By giving it the Merkle Proof and the original values
            // It calculates `address` using msg.sender`, and we provide it the number of NFTs
            // that the address can mint
            bool verified = whitelist.checkInWhitelist(proof, VALUE);
            assertTrue(verified);
        }
    }

    function testInvalidProof() public {

        // Valid address
        vm.prank(vm.addr(1));

        // make an empty bytes32 array as an invalid proof
        bytes32[] memory invalidProof;

        // Check for invalid address
        bool verifiedInvalid = whitelist.checkInWhitelist(invalidProof, VALUE);
        assertFalse(verifiedInvalid);
        
    }

    function testInvalidValue() public {

        // get proof from the Merkle tree
        bytes32[] memory proof = m.getProof(list, 0);

        // Valid address
        vm.prank(vm.addr(1));
   
        bool verified = whitelist.checkInWhitelist(proof, VALUE + 1);
        assertFalse(verified);

    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    // function to encoding leaf nodes
    function _encodeLeaf(address _address, uint64 _spots) internal pure returns (bytes32) {
        // we are using keccak256 as hashing algorithm
        return keccak256(abi.encodePacked(_address, _spots));
    }

    function _generateRoot(uint256 length) internal returns (bytes32) {
        

        // create an array of elements to put in the Merkle tree
        for (uint8 i = 0; i < length; i++) {
            list[i] = _encodeLeaf(vm.addr(i + 1), VALUE);
        }

        // compute the merkle root
        root = m.getRoot(list);
        return root;
    }

}
