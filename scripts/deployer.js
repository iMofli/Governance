// Contract Deploy Script Execution
// cli: npx hardhat --network networkName run scriptName

// Contract Verification in Etherscan
// cli: npx hardhat verify --network networkName contractAddress

// Set Up Contract as Proxy in Etherscan
// contract section -> more options (in contract source code) -> is this a proxy?

// Contract Parameters

// Contract Name: IdentificationRegistryContract
// ERC721 Name: The Gov ZK Protocol
// ERC721 Symbol: GOV

const { ethers, upgrades } = require('hardhat');
const { VOTING_PERIOD, VOTING_DELAY, QUORUM_PERCENTAGE } = require('../test/utils/governanceUtils');

const identificationRegistryContract = 'IdentificationRegistryContract';
const governanceContractName = 'GovernanceUpgradeable';
const erc721Name = 'The Gov ZK Protocol';
const erc721Symbol = 'GOV';
const merkleTreeRoot = '0x2ad38e8172f4c0c361712d901f397a816a7d2839f21d3edbfcfb32ba53278d62';
const ipfsHash = 'QmNxC3pms2ZtNicUjhKgGVzvcqETGEZX92jB8qK9ynzcuf';
const proxyAddressToken = '0x2F3Bfc0FCeAd5Ec979137044e30afDc0f64e4d89';
const proxyAddressGovernance = '0xE8416604608F224637615F2F9117BA0e71eba56F';

const deployContract = async () => {

  console.log('Contract Deploy - Not Upgradeable - Contract Name: ', identificationRegistryContract);

  const IdentificationRegistry = await ethers.getContractFactory(identificationRegistryContract);
  const identificationRegistry = await IdentificationRegistry.deploy(erc721Name, erc721Symbol, merkleTreeRoot, ipfsHash);

  await identificationRegistry.deployed();

  console.log('Contract Deployed To: ', identificationRegistry.address);
}

const deployWithProxyToken = async () => {

  console.log('Contract Deploy - Upgradeable - Contract Name: ', identificationRegistryContract);

  const IdentificationRegistry = await ethers.getContractFactory(identificationRegistryContract);
  const identificationRegistry = await upgrades.deployProxy(IdentificationRegistry, [erc721Name, erc721Symbol, merkleTreeRoot, ipfsHash]);

  await identificationRegistry.deployed();

  console.log('Contract Proxy Deployed To: ', identificationRegistry.address);
}

const deployWithProxyGovernance = async () => {

  console.log('Contract Deploy - Upgradeable - Contract Name: ', governanceContractName);

  const GovernanceContract = await ethers.getContractFactory(governanceContractName);
  const governanceContract = await upgrades.deployProxy(GovernanceContract, [proxyAddressToken, VOTING_DELAY, VOTING_PERIOD, QUORUM_PERCENTAGE]);

  await governanceContract.deployed();

  console.log('Contract Proxy Deployed To: ', governanceContract.address);
}

const upgradeImplementationToken = async () => {

  console.log('Contract Deploy - Upgrade Implementation Contract - Contract Name: ', identificationRegistryContract);

  const IdentificationRegistry = await ethers.getContractFactory(identificationRegistryContract);
  const identificationRegistry = await upgrades.upgradeProxy(proxyAddressToken, IdentificationRegistry);

  console.log('Contract Implementation Upgraded');
}

const upgradeImplementationGovernance = async () => {

  console.log('Contract Deploy - Upgrade Implementation Contract - Contract Name: ', governanceContractName);

  const GovernanceContract = await ethers.getContractFactory(governanceContractName);
  const governanceContract = await upgrades.upgradeProxy(proxyAddressGovernance, GovernanceContract);

  console.log('Contract Implementation Upgraded');
}

const changeIpfsHash = async () => {
    const IdentificationRegistry = await ethers.getContractFactory(identificationRegistryContract);
    const identificationRegistry = await IdentificationRegistry.attach(proxyAddressToken);
    await identificationRegistry.updateCensus(0, merkleTreeRoot, ipfsHash);
}

const deploy = async () => {
  try {
    // await deployContract();
    await deployWithProxyGovernance();
    //await deployWithProxyToken();
    //await upgradeImplementation();
    //await upgradeImplementationGovernance()
    //await changeIpfsHash();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

deploy();