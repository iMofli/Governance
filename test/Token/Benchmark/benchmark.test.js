const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const crypto = require("crypto")

const IPFS_HASH = "QmdKYfvbpe3bFzNZ4uANZSnbzeTu2iUHxQyEhMrxod7eih";

describe("Benchmark", function () {
    let benchmark = null;
    let owner = null;
    let addr1 = null;
    const NUMBER_OF_ADDRESSES_TO_ALLOW = 2048;

    beforeEach(async function () {
        const dv = await ethers.getContractFactory("Benchmark");
        [owner, addr1] = await ethers.getSigners();

        Benchmark = await dv.deploy();
        await Benchmark.deployed();
    });

    describe("benchmarks", async function () {


        it("test mapping", async function () {
            await Benchmark.setMapping(addr1.address);
            await expect(Benchmark.connect(addr1).benchmarkMapping()).to.not.be.reverted;
        });


        // heavily inspired by https://github.com/OpenZeppelin/workshops/blob/master/06-nft-merkle-drop/test/4-ERC721MerkleDrop.test.js
        it("test merkle trees", async function () {
            function hashAddress(address) {
                return Buffer.from(ethers.utils.solidityKeccak256(['address'], [address]).slice(2), 'hex')
            }

            let addresses = [];
            for (let i = 0; i < NUMBER_OF_ADDRESSES_TO_ALLOW; i++) {
                let privateKey = "0x" + crypto.randomBytes(32).toString('hex');
                addresses.push(new ethers.Wallet(privateKey).address);
            }

            // put the test address in the middle
            addresses[Math.floor(addresses.length / 2)] = addr1.address;

            const merkleTree = new MerkleTree(Object.entries(addresses).map(address => hashAddress(address[1])), keccak256, { sortPairs: true });
            const proof = merkleTree.getHexProof(hashAddress(addr1.address));
            await Benchmark.setMerkleCensus(merkleTree.getHexRoot(), IPFS_HASH);

            await expect(Benchmark.connect(addr1).benchmarkMerkleTree(proof)).to.not.be.reverted;
        })
    });
});