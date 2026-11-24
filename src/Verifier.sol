// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LamportVerifier {
    //verification function
    function verify(bytes32 digest, bytes32[256] memory signature, bytes32[2][256] memory publicKey) public pure returns (bool){
        
        //go through all 256 bits
        for (uint256 i = 0; i < 256; i++) {

            //set bit to be the bit we want to look at
            //find which byte it belongs to, find its position (i % 8)
            //shift it to the right end and use & 1 to keep only that bit
            uint256 bit = (uint8(digest[i / 8]) >> (7 - (i % 8))) & 1;
            
            //check if the hash (sha256) of the secret value is not equal to the selected pk hash
            if (sha256(abi.encodePacked(signature[i])) != publicKey[i][bit]) {
                return false;
            }
        }
        return true;
    }

    //to compute the commitment
    function computeCommitment(bytes32[2][256] memory publicKey) public pure returns (bytes32){
        return sha256(abi.encode(publicKey));
    }

    //verification function with commitments
    function verifyWithCommitment(bytes32 digest, bytes32[256] memory signature, bytes32[2][256] memory publicKey, bytes32 expectedCommit) public pure returns (bool){
        
        if (computeCommitment(publicKey) != expectedCommit) {
            return false;
        }
        return verify(digest, signature, publicKey);
    }
}
