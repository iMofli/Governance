const { expect } = require("chai");
const { hre, ethers } = require("hardhat");

const { buildMerkleTree, buildProofsAndLeaves } = require("./utils/merkleLogic");
const { deployToken, deployGovernance } = require("./utils/deployer");
const { VOTING_DELAY, VOTING_PERIOD, QUORUM_PERCENTAGE, PROPOSAL_DESCRIPTION } = require("./utils/governanceUtils");

const IPFS_HASH = "QmdKYfvbpe3bFzNZ4uANZSnbzeTu2iUHxQyEhMrxod7eih";
const ownerTokenId = 9111111983;
const addr1TokenId = 5380007180;
const addr2TokenId = 1111111188;




describe("Governance", function () {
    let governanceContract;
    let tokenContract;
    let merkleTree;
    let owner;
    let addr1;
    let addr2;
    let addrNotWhitelisted;
    let hashOwner;
    let hashAddr1;
    let hashAddr2;
    let hashAddrNotWhitelisted;
    let ownerProof;
    let addr1Proof;
    let addrNotWhiteListedProof;
    let addr2Proof;
    let ownerTokenIdAddress;
    let addr1TokenIdAddress;
    let addr2TokenIdAddress

    before(async () => {
        merkleTree = buildMerkleTree();
        [hashOwner, hashAddr1, hashAddr2, hashAddrNotWhitelisted, ownerProof, addr1Proof, addr2Proof,
            addrNotWhiteListedProof] = await buildProofsAndLeaves();
        [owner, addr1, addr2, addrNotWhitelisted] = await ethers.getSigners();
    })

    beforeEach(async() => {
        tokenContract = await deployToken(merkleTree, IPFS_HASH);
        governanceContract = await deployGovernance(tokenContract.address);
        await tokenContract.whiteListMint(ownerTokenId, ownerProof);
        await tokenContract.connect(addr1).whiteListMint(addr1TokenId, addr1Proof);
        await tokenContract.connect(addr2).whiteListMint(addr2TokenId, addr2Proof);
        ownerTokenIdAddress = await governor._parseTokenIdToAddress(ownerTokenId);
        addr1TokenIdAddress = await governor._parseTokenIdToAddress(addr1TokenId);
        addr2TokenIdAddress = await governor._parseTokenIdToAddress(addr2TokenId);
    })

    describe("Workflow correct", function () {
        it("Initialitzation ok", async function () {
            expect(await tokenContract.merkleRoot()).to.equal(merkleTree.getHexRoot());
            expect(await tokenContract.ipfsHash()).to.equal(IPFS_HASH);
            expect(await tokenContract.name()).to.equal("Test");
            expect(await tokenContract.symbol()).to.equal("T");
            expect(await governanceContract.votingDelay()).to.equal(VOTING_DELAY);
            expect(await governanceContract.votingPeriod()).to.equal(VOTING_PERIOD);
            expect(await governanceContract.quorumNumerator()).to.equal(QUORUM_PERCENTAGE);
            expect(await governanceContract.proposalThreshold()).to.equal(1);
        })

        it("TokenIdToAddress", async function() {
            expect(ownerTokenIdAddress).to.be.properAddress;
            expect(addr1TokenIdAddress).to.be.properAddress;
            expect(addr2TokenIdAddress).to.be.properAddress;
        })

        it("Check Process Ok", async function() {
            const tx = await (governanceContract.propose(PROPOSAL_DESCRIPTION, ownerTokenId));
            expect(tx).to.emit(governanceContract, 'ProposalCreated');
            const receipt = await tx.wait(1);
            const proposalId = receipt.events[0].args.proposalId;
            let proposalState = await governanceContract.state(proposalId);
            let bn = await ethers.provider.getBlockNumber();
            expect(await governanceContract.getVotes(ownerTokenId, bn)).to.equal(1);
            // proposalState: 0 = pending, 1 = Active, 2 = Defeated, 3 = Succeded, 4 = Expired
            expect(proposalState).to.equal(0);
            //make votation start (VOTING DELAY: 1 BLOCK)
            await ethers.provider.send("evm_mine", []);

            // owner vote
            const voteTx = await governanceContract.castVote(proposalId, 1, ownerTokenId);
            expect(voteTx).to.emit(governanceContract, 'VoteCast');
            expect(await governanceContract.hasVoted(proposalId, ownerTokenId)).to.be.true;
            expect(await governanceContract.hasVoted(proposalId, addr2TokenId)).to.be.false;

            // addr2 vote
            await governanceContract.connect(addr2).castVote(proposalId, 1, addr2TokenId);
            expect(await governanceContract.hasVoted(proposalId, addr2TokenId)).to.be.true;
            expect(await governanceContract.hasVoted(proposalId, addr1TokenId)).to.be.false;

            // addr1 vote
            await governanceContract.connect(addr1).castVote(proposalId, 0, addr1TokenId);
            expect(await governanceContract.hasVoted(proposalId, addr2TokenId)).to.be.true;

            proposalState = await governanceContract.state(proposalId);
            expect(proposalState).to.equal(1);

            await ethers.provider.send("evm_mine", []);
            await ethers.provider.send("evm_mine", []);
            await ethers.provider.send("evm_mine", []);
            proposalState = await governanceContract.state(proposalId);
            // proposalState: 0 = pending, 1 = Active, 2 = Defeated, 3 = Succeded, 4 = Expired
            expect(proposalState).to.equal(3);

            //check function fetchProposalData
            let { votingDelay,
                forVotes,
                againstVotes,
                abstainVotes,
                totalSupply,
                state } = await governanceContract.fetchProposalData(proposalId);
            expect(votingDelay).to.equal(1);
            expect(forVotes).to.equal(2);
            expect(againstVotes).to.equal(1);
            expect(abstainVotes).to.equal(0);
            expect(totalSupply).to.equal(3);
            expect(state).to.equal(3);
        })

        it("Check process with delegations", async function() {
            await tokenContract.delegate(ownerTokenId, addr1TokenId);
            // can propose because we use vote of block - 1
            const tx = await (governanceContract.propose(PROPOSAL_DESCRIPTION, ownerTokenId));
            expect(tx).to.emit(governanceContract, 'ProposalCreated');
            const receipt = await tx.wait(1);
            const proposalId = receipt.events[0].args.proposalId;

            // mine to start votation
            await ethers.provider.send("evm_mine", []);
            await ethers.provider.send("evm_mine", []);
            //check is active
            let proposalState = await governanceContract.state(proposalId);
            expect(proposalState).to.equal(1);

            //owner cast vote, should count 0 votes
            await expect(governanceContract.castVote(proposalId, 1, ownerTokenId));
            let {forVotes, againstVotes, abstainVotes} = await governanceContract.proposalVotes(proposalId);
            expect(forVotes).to.equal(0);
            expect(againstVotes).to.equal(0);
            expect(abstainVotes).to.equal(0);

            //addr1 vote
            await governanceContract.connect(addr1).castVote(proposalId, 0, addr1TokenId);

            //addr2 vote
            await governanceContract.connect(addr2).castVote(proposalId, 1, addr2TokenId);

            // mint to end the process
            await ethers.provider.send("evm_mine", []);
            await ethers.provider.send("evm_mine", []);

            //check if defeated
            proposalState = await governanceContract.state(proposalId);
            expect(proposalState).to.equal(2);
        })

        it("Check cannot propose if has no voting weight", async function() {
            await tokenContract.delegate(ownerTokenId, addr1TokenId);
            await ethers.provider.send("evm_mine", []);
            await expect(governanceContract.propose(PROPOSAL_DESCRIPTION, ownerTokenId))
                .to.be.revertedWith("Governor: proposer votes below proposal threshold");
        })

        it("Check cannot propose vote if not the owner of the tokenId", async function() {
            await expect(governanceContract.connect(addr1).propose(PROPOSAL_DESCRIPTION, ownerTokenId))
                .to.be.revertedWith("ERC721Upgradeable: Address not owner of the token");

            const tx = await governanceContract.propose(PROPOSAL_DESCRIPTION, ownerTokenId);
            expect(tx).to.emit(governanceContract, 'ProposalCreated');
            const receipt = await tx.wait(1);
            const proposalId = receipt.events[0].args.proposalId;

            await ethers.provider.send("evm_mine", []);
            await ethers.provider.send("evm_mine", []);

            await expect(governanceContract.connect(addr1).castVote(proposalId, 1, ownerTokenId))
                .to.be.revertedWith('ERC721Upgradeable: Address not owner of the token');

        })
    })
});


