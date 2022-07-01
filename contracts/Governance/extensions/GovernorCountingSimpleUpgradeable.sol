// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Extension of {GovernorUpgradeable} for simple, 3 options, vote counting.
abstract contract GovernorCountingSimpleUpgradeable is Initializable, GovernorUpgradeable {
    function __GovernorCountingSimple_init() internal onlyInitializing {
    }

    function __GovernorCountingSimple_init_unchained() internal onlyInitializing {
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    // # of against, for and abstain votes for a proposal
    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;


    function _hasVoted(uint256 proposalId, address account) internal view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    // Accessor to the internal vote counts.
    function proposalVotes(uint256 proposalId) public view virtual
    returns (
        uint256 againstVotes,
        uint256 forVotes,
        uint256 abstainVotes
    ) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
    }

    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return quorum(proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes + proposalvote.againstVotes;
    }

    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        // check if has already voted
        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}