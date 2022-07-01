const { expect } = require("chai");
const { ethers } = require("hardhat");
const { buildMerkleTree, buildProofsAndLeaves } = require("./utils/merkleLogic");
const { deployToken } = require("./utils/deployer");

const IPFS_HASH = "QmdKYfvbpe3bFzNZ4uANZSnbzeTu2iUHxQyEhMrxod7eih";
const ownerTokenId = 9111111983;
const addr1TokenId = 5380007180;
const addr2TokenId = 1111111188;
const addrNotWhitelistedTokenId = 8888888890;


describe("IdentificationRegistryContract", function () {
    let contract;
    let merkleTree;
    let hashOwner;
    let hashAddr1;
    let hashAddr2;
    let hashAddrNotWhitelisted;
    let ownerProof;
    let addr1Proof;
    let addr2Proof;
    let addrNotWhiteListedProof;


    before(async() => {
        merkleTree = buildMerkleTree();
        [hashOwner, hashAddr1, hashAddr2, hashAddrNotWhitelisted, ownerProof, addr1Proof, addr2Proof,
            addrNotWhiteListedProof] = await buildProofsAndLeaves();
        [owner, addr1, addr2, addrNotWhitelisted] = await ethers.getSigners();
    })

    beforeEach(async() => {
        contract = await deployToken(merkleTree, IPFS_HASH);
    })

    const mintTokens = async() => {
        await contract.whiteListMint(ownerTokenId, ownerProof);
        await contract.connect(addr1).whiteListMint(addr1TokenId, addr1Proof);
        await contract.connect(addr2).whiteListMint(addr2TokenId, addr2Proof);
    }

    const checkVotesTotalSupply = async(expected) => {
        // return function to private
        expect(await contract.getTotalSupply()).to.be.equal(expected);
    }

    describe("Identification Registry base contract", function() {
        it("Expect initialize correctly", async function() {
            expect(await contract.name()).to.equal("Test");
            expect(await contract.symbol()).to.equal("T");
            expect(await contract.merkleRoot()).to.equal(merkleTree.getHexRoot());
            expect(await contract.ipfsHash()).to.equal(IPFS_HASH);

        })

        it("Expect mint only if addr in whiteList", async function() {
            expect(await contract.balanceOf(owner.address)).to.equal(0);
            await mintTokens();
            // check balances
            expect(await contract.balanceOf(owner.address)).to.equal(1);
            expect(await contract.balanceOf(addr1.address)).to.equal(1);
            expect(await contract.balanceOf(addr2.address)).to.equal(1);
            // check enumerability
            expect(await contract.tokenOfOwnerByIndex(owner.address, 0)).to.equal(ownerTokenId);
            expect(await contract.tokenOfOwnerByIndex(addr1.address, 0)).to.equal(addr1TokenId);
            expect(await contract.tokenOfOwnerByIndex(addr2.address, 0)).to.equal(addr2TokenId);

        })

        it("Revert if try to mint with wrong ID", async function() {
            await expect(contract.whiteListMint("1111111190", ownerProof))
                .to.be.revertedWith("IdentificationRegistryContract: Address-ID Not In Whitelist");
        })

        it("Revert if addr not in whitelist", async function() {
            await expect(contract.connect(addrNotWhitelisted).whiteListMint(addrNotWhitelistedTokenId, addrNotWhiteListedProof))
                .to.be.revertedWith("IdentificationRegistryContract: Address-ID Not In Whitelist");
        })

        it("Expect revert if mint already claimed", async function() {
            await contract.whiteListMint(ownerTokenId, ownerProof);
            await expect(contract.whiteListMint(ownerTokenId, ownerProof))
                .to.be.revertedWith("IdentificationRegistryContract: TokenId Already Claimed");
        })

        it("updateCensus emits event", async function() {
            await expect(contract.updateCensus(addrNotWhitelistedTokenId, merkleTree.getHexRoot(), IPFS_HASH))
                .to.emit(contract, 'UpdateCensus')
                .withArgs(addrNotWhitelistedTokenId, merkleTree.getHexRoot, IPFS_HASH);
        })

        it("Revert if updateCensus signer is not the owner", async function() {
            await expect(contract.connect(addr1).updateCensus(addr1TokenId, merkleTree.getHexRoot(), IPFS_HASH))
                .to.be.revertedWith("Ownable: caller is not the owner");
        })
    })

    describe("ERC721 Votes: Test delegation & voting weight module", function() {

        it("Expect token minted to have voting power", async function() {
            await contract.whiteListMint(ownerTokenId, ownerProof);
            expect(await contract.getVotes(ownerTokenId)).to.equal(1);
            await checkVotesTotalSupply(1);
        })

        it("Expect tokenMinted to emit event", async function() {
            await expect(contract.whiteListMint(ownerTokenId, ownerProof))
                .to.emit(contract, 'DelegateCreated').withArgs(ownerTokenId);

            await expect(contract.connect(addr1).whiteListMint(addr1TokenId, addr1Proof))
                .to.emit(contract, 'DelegateCreated').withArgs(addr1TokenId);

        })

        it("Delegate votes work properly", async function() {
            await mintTokens();
            expect(await contract.delegates(ownerTokenId)).to.equal(ownerTokenId);
            expect(await contract.delegates(addr1TokenId)).to.equal(addr1TokenId);
            await contract.delegate(ownerTokenId, addr1TokenId);

            expect(await contract.getVotes(ownerTokenId)).to.equal(0);
            expect(await contract.delegates(ownerTokenId)).to.equal(addr1TokenId);
            expect(await contract.getVotes(addr1TokenId)).to.equal(2);
            await checkVotesTotalSupply(3);
        })

        it("Revert when sender not owner of the tokenId", async function() {
            await mintTokens();
            await expect(contract.delegate(addr1TokenId, addr2TokenId)).to.be.revertedWith("VotesUpgradeable: Wallet not owner of the tokenId");
        })

        it("Revert when delegating to a tokenId already delegated", async function() {
            await mintTokens();
            await contract.delegate(ownerTokenId, addr1TokenId);
            await expect(contract.connect(addr2).delegate(addr2TokenId, ownerTokenId)).to.be.revertedWith("VotesUpgradeable: Delegatee has already delegated");
        })

        it("Expect to return votes to delegated tokenId when delegating", async function() {
            await mintTokens();
            await expect(contract.delegate(ownerTokenId, addr1TokenId))
                .to.emit(contract, 'DelegateChanged').withArgs(ownerTokenId, ownerTokenId, addr1TokenId);

            expect(await contract.getVotes(ownerTokenId)).to.equal(0);
            expect(await contract.getVotes(addr1TokenId)).to.equal(2);

            // Now addr1 delegate to addr2: should return vote to owner.
            // TODO: in waffle 4.0 it would be able to chain events. Upgrade when available. By now tested individually.
            await expect(contract.connect(addr1).delegate(addr1TokenId, addr2TokenId))
                //.to.emit(contract, 'DelegateChanged').withArgs(ownerTokenId, addr1TokenId, ownerTokenId)
                //.to.emit(contract, 'DelegateChanged').withArgs(addr1TokenId, addr1TokenId, addr2TokenId)
                //.to.emit(contract, 'DelegateVotesChanged').withArgs(ownerTokenId, 0, 1)
                .to.emit(contract, 'DelegateVotesChanged').withArgs(addr1TokenId, 2, 0);
                //.to.emit(contract, 'DelegateVotesChanged').withArgs(addr2TokenId, 1, 2);

            expect(await contract.getVotes(ownerTokenId)).to.equal(1);
            expect((await contract.getDelegatedIdsForTokenId(ownerTokenId)).length).to.equal(1);

            expect(await contract.getVotes(addr1TokenId)).to.equal(0);
            expect((await contract.getDelegatedIdsForTokenId(addr1TokenId)).length).to.equal(0);

            expect(await contract.getVotes(addr2TokenId)).to.equal(2);
            expect((await contract.getDelegatedIdsForTokenId(addr2TokenId)).length).to.equal(2);
            await checkVotesTotalSupply(3);

        })

        it("Expect return votes when tokenId removed from census", async function() {
            await mintTokens();
            await contract.delegate(ownerTokenId, addr1TokenId);
            await expect(contract.updateCensus(addr1TokenId, merkleTree.getHexRoot(), IPFS_HASH))
                .to.emit(contract, 'DelegateRemoved').withArgs(addr1TokenId);

            expect(await contract.getVotes(ownerTokenId)).to.equal(1);
            expect((await contract.getDelegatedIdsForTokenId(ownerTokenId)).length).to.equal(1);

            expect(await contract.getVotes(addr1TokenId)).to.equal(0);
            expect((await contract.getDelegatedIdsForTokenId(addr1TokenId)).length).to.equal(0);
            await checkVotesTotalSupply(2);
        })

        it("Expect voting unit is removed for token that the tokenId burned has delegated", async function() {
            await mintTokens();
            await contract.connect(addr1).delegate(addr1TokenId, addr2TokenId);
            await contract.delegate(ownerTokenId, addr2TokenId);

            expect(await contract.getVotes(addr1TokenId)).to.equal(0);
            expect(await contract.getVotes(addr2TokenId)).to.equal(3);

            await expect(contract.updateCensus(addr1TokenId, merkleTree.getHexRoot(), IPFS_HASH))
                .to.emit(contract, 'DelegateRemoved').withArgs(addr1TokenId);

            expect(await contract.getVotes(addr2TokenId)).to.equal(2);
            expect((await contract.getDelegatedIdsForTokenId(addr2TokenId)).length).to.equal(2);

            expect(await contract.getVotes(addr1TokenId)).to.equal(0);
            expect((await contract.getDelegatedIdsForTokenId(addr1TokenId)).length).to.equal(0);

            await checkVotesTotalSupply(2);
        })

        it("Test for multiple delegation to one token and return as expected", async function() {
            await mintTokens();
            await contract.connect(addr1).delegate(addr1TokenId, addr2TokenId);
            await contract.delegate(ownerTokenId, addr2TokenId);

            await contract.updateCensus(addr2TokenId, merkleTree.getHexRoot(), IPFS_HASH);

            expect(await contract.getVotes(addr2TokenId)).to.equal(0);
            expect((await contract.getDelegatedIdsForTokenId(addr2TokenId)).length).to.equal(0);

            expect(await contract.getVotes(addr1TokenId)).to.equal(1);
            expect((await contract.getDelegatedIdsForTokenId(addr1TokenId)).length).to.equal(1);

            expect(await contract.getVotes(ownerTokenId)).to.equal(1);
            expect((await contract.getDelegatedIdsForTokenId(ownerTokenId)).length).to.equal(1);

            await checkVotesTotalSupply(2);
        })

        it("Delegate to another token when already have delegated to another token", async function() {
            await mintTokens();
            await contract.delegate(ownerTokenId, addr2TokenId);
            await contract.delegate(ownerTokenId, addr1TokenId);

            expect(await contract.getVotes(addr1TokenId)).to.equal(2);
            expect((await contract.getDelegatedIdsForTokenId(addr1TokenId)).length).to.equal(2);

            expect(await contract.getVotes(ownerTokenId)).to.equal(0);
            expect((await contract.getDelegatedIdsForTokenId(ownerTokenId)).length).to.equal(0);

            expect(await contract.getVotes(addr2TokenId)).to.equal(1);
            expect((await contract.getDelegatedIdsForTokenId(addr2TokenId)).length).to.equal(1);
        })
    })
});

