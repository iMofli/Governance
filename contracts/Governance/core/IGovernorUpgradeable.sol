// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


abstract contract IGovernorUpgradeable is Initializable {
    function __IGovernor_init() internal onlyInitializing {
    }

    function __IGovernor_init_unchained() internal onlyInitializing {
    }

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        QuorumNotReached
    }

    // Emitted when a proposal is created
    event ProposalCreated(
        uint256 proposalId,
        uint256 tokenId,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight);

    function name() public view virtual returns (string memory);

    function hashProposal(
        uint256 blockNumber,
        uint256 tokenId,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    function state(uint256 proposalId) public view virtual returns (ProposalState);

    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    function votingDelay() public view virtual returns (uint256);

    function votingPeriod() public view virtual returns (uint256);

    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    function getVotes(uint256 tokenId, uint256 blockNumber) public view virtual returns (uint256);

    function hasVoted(uint256 proposalId, uint256 tokenId) external view virtual returns (bool);

    function propose(
        string memory description,
        uint256 tokenId
    ) public virtual returns (uint256 proposalId);

    function castVote(uint256 proposalId, uint8 support, uint256 tokenId) public virtual returns (uint256 balance);
 
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
