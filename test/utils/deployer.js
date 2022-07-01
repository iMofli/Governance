const {ethers} = require("hardhat");
const { VOTING_DELAY, VOTING_PERIOD, QUORUM_PERCENTAGE } = require("./governanceUtils");


const deployToken = async (merkleTree, IPFS_HASH) => {
    const IdentificationRegistry = await ethers.getContractFactory("IdentificationRegistryContract");
    const contract = await IdentificationRegistry.deploy();
    await contract.deployed();
    await contract.initialize("Test", "T", merkleTree.getHexRoot(), IPFS_HASH);
    return contract;
}

const deployGovernance = async(tokenAddress) => {
    const Governor = await ethers.getContractFactory("GovernanceUpgradeable");
    governor = await Governor.deploy();
    await governor.deployed();
    await governor.initialize(tokenAddress, VOTING_DELAY, VOTING_PERIOD, QUORUM_PERCENTAGE);
    return governor;
}

module.exports = { deployToken, deployGovernance };