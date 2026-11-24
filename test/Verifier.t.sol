// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LamportVerifier} from "../src/Verifier.sol";

contract LamportVerifierTest is Test {
    LamportVerifier verifier;

    function setUp() public {
        verifier = new LamportVerifier();
    }

    function testValidSignature() public {
        bytes32 digest = bytes32(0);
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        //test values:
        for (uint256 i = 0; i < 256; i++) {

            signature[i] = bytes32(i + 1);
            publicKey[i][0] = sha256(abi.encodePacked(signature[i]));

        }

        assertTrue(verifier.verify(digest, signature, publicKey));
    }

    function testInvalidSignature() public {
        bytes32 digest = bytes32(0);
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {

            signature[i] = bytes32(i + 1);
            publicKey[i][0] = sha256(abi.encodePacked(signature[i]));

        }

        signature[88] = bytes32(uint256(765));
        
        assertFalse(verifier.verify(digest, signature, publicKey));
    }

    function testValidSignatureAllOnes() public {
        //bytes32 digest = bytes32(0); //for fail of assert test
        bytes32 digest = bytes32(type(uint256).max); //to get all 256 bits set to 1s
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);
            publicKey[i][1] = sha256(abi.encodePacked(signature[i]));
        }
        assertTrue(verifier.verify(digest, signature, publicKey));
    }

    function testValidSignatureFirstBitOne() public {
        //also helps to make sure direction is correct
        bytes32 digest = bytes32(uint256(1) << 255); //num 1 shifted by 255 pos so that all 0s except first bit
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);

            if (i == 0) {
                publicKey[i][1] = sha256(abi.encodePacked(signature[i]));
            } else {
                publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
            }
        }
        assertTrue(verifier.verify(digest, signature, publicKey));
    }

    function testInvalidSignatureModifiedDigest() public {
        //Change the first bit of digest from 1 to 0 meaning the verifier will still check publicKey[0][0] instead of publicKey[0][1] 
        //The original revealed secret should no longer match

        bytes32 digest = bytes32(uint256(1) << 255); //num 1 shifted by 255 pos so that all 0s except first bit
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);

            if (i == 0) {
                publicKey[i][1] = sha256(abi.encodePacked(signature[i]));
            } else {
                publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
            }
        }
        digest = bytes32(0);
        assertFalse(verifier.verify(digest, signature, publicKey));
    }

    function testModifiedPK() public {
        bytes32 digest = bytes32(0);
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);
            publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
        }
        publicKey[88][0] = bytes32(0); //replace the hash with 32 bytes of 0
        assertFalse(verifier.verify(digest, signature, publicKey));
    }

    //this one should ret True because no commitments yet, so no check
    function testModifiedUnusedPK() public {
        bytes32 digest = bytes32(0);
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);
            publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
        }
        publicKey[88][1] = bytes32(uint256(999));        
        assertTrue(verifier.verify(digest, signature, publicKey));
    }

    function testValidSignatureSecondByte() public {
        bytes32 digest = bytes32(uint256(1) << 247); //to set only that bit, shift is 255 - 8 = 247   
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);

            if (i == 8) { //for the position 8 instead of position 0 from before
                publicKey[i][1] = sha256(abi.encodePacked(signature[i]));
            } else {
                publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
            }
        }
        assertTrue(verifier.verify(digest, signature, publicKey));
    }

    //test changing the commitment
    function testCommitmentChanges() public {
        bytes32[2][256] memory publicKey;
        bytes32 comm = verifier.computeCommitment(publicKey);
        publicKey[88][1] = bytes32(uint256(1));
        bytes32 comm2 = verifier.computeCommitment(publicKey);
        assertNotEq(comm, comm2);
    }

    //test verifying with commitment
    function testValidSigWithCommitment() public {
        bytes32 digest = bytes32(0);
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        //test values:
        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);
            publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
        }
        bytes32 expectedCommit = verifier.computeCommitment(publicKey);

        assertTrue(verifier.verifyWithCommitment(digest, signature, publicKey, expectedCommit));
    }

    function testCommitRejectModUnusedPK() public {
        bytes32 digest = bytes32(0);
        bytes32[256] memory signature;
        bytes32[2][256] memory publicKey;

        //test values:
        for (uint256 i = 0; i < 256; i++) {
            signature[i] = bytes32(i + 1);
            publicKey[i][0] = sha256(abi.encodePacked(signature[i]));
        }
        bytes32 expectedCommit = verifier.computeCommitment(publicKey);
        publicKey[88][1] = bytes32(uint256(999));
        assertFalse(verifier.verifyWithCommitment(digest, signature, publicKey, expectedCommit));
        
    }

}