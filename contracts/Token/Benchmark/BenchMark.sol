// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Benchmark  {

    bytes32 public merkleRoot;
    string public ipfsHash;

    mapping(address => bool) public allowList;

    //needed in order to get the gas report
    uint256 public aux;

    function setMapping(address _buyer) external {
        allowList[_buyer] = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }

    function setIpfsHash(string calldata _ipfsHash) internal {
        ipfsHash = _ipfsHash;
    }

    function setMerkleCensus(bytes32 _merkleRoot, string calldata _ipfsHash) external {
        setMerkleRoot(_merkleRoot);
        setIpfsHash(_ipfsHash);
    }

    function benchmarkMapping() external {
        require(allowList[msg.sender] == true, "not allowed");
        if (false) {
            aux = 1;
        }
    }

    function benchmarkMerkleTree(bytes32[] calldata merkleProof) external {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(
                    abi.encodePacked(msg.sender))),
            "Invalid merkle proof");
        if (false) {
            aux = 1;
        }
    }
}