const addresses = require("./addresses.json");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");

const ownerTokenId = 9111111983;
const addr1TokenId = 5380007180;
const addr2TokenId = 1111111188;
const addrNotWhitelistedTokenId = 8888888890;

const buildMerkleTree = () => {
    let leaves = addresses.map(item => computeLeaf(item.address, item.tokenId));
    const merkle = new MerkleTree(leaves, ethers.utils.keccak256, { sortPairs: true });
    return merkle;
}

const computeLeaf = (address, tokenId) => {
    return ethers.utils.solidityKeccak256(["address", "uint256"], [address, tokenId]);
}

const buildProofsAndLeaves = async () => {
    const merkleTree = buildMerkleTree();
    [owner, addr1, addr2, addrNotWhiteListed] =  await ethers.getSigners();
    const hashOwner = computeLeaf(owner.address, ownerTokenId);
    const hashAddr1 = computeLeaf(addr1.address, addr1TokenId);
    const hashAddr2 = computeLeaf(addr2.address, addr2TokenId);
    const hashAddrNotWhitelisted = computeLeaf(addrNotWhiteListed.address, addrNotWhitelistedTokenId);
    const ownerProof = merkleTree.getHexProof(hashOwner);
    const addr1Proof = merkleTree.getHexProof(hashAddr1);
    const addr2Proof = merkleTree.getHexProof(hashAddr2);
    const addrNotWhiteListedProof = merkleTree.getHexProof(hashAddrNotWhitelisted);

    return [hashOwner, hashAddr1, hashAddr2, hashAddrNotWhitelisted, ownerProof, addr1Proof, addr2Proof, addrNotWhiteListedProof];
}

module.exports = { buildMerkleTree, computeLeaf, buildProofsAndLeaves };