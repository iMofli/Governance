// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./core/GovernorUpgradeable.sol";
import "./extensions/GovernorSettingsUpgradeable.sol";
import "./extensions/GovernorCountingSimpleUpgradeable.sol";
import "./Votes/GovernorVotesUpgradeable.sol";
import "./extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GovernanceUpgradeable is Initializable, GovernorUpgradeable, GovernorVotesUpgradeable, GovernorVotesQuorumFractionUpgradeable,
    GovernorSettingsUpgradeable, GovernorCountingSimpleUpgradeable  {

    struct ProposalData {
        uint256 votingDelay;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 totalSupply;
        IGovernorUpgradeable.ProposalState state;
    }

    function initialize(
        IVotesUpgradeable _token,
        uint256 _votingDelay,   /* In blocks */
        uint256 _votingPeriod, /* In blocks */
        uint256 _quorumPercentage /* % */
        ) initializer public
    {
        __Governor_init("Governance");
        __GovernorSettings_init(_votingDelay, _votingPeriod, 1 /* Proposal threshold (#Votes) */ );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(_quorumPercentage);
    }

    function fetchProposalData(uint256 proposalId) external view returns (ProposalData memory) {
        uint256 snapshot = proposalSnapshot(proposalId);
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = proposalVotes(proposalId);
        uint256 totalSupply = block.number <= snapshot ? 0 : super.votesTotalSupply(snapshot);
        ProposalData memory data = ProposalData(super.votingDelay(), forVotes, againstVotes, abstainVotes, totalSupply, super.state(proposalId));
        return data;
    }


    function proposalThreshold()
    public
    view
    override(GovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        return super.proposalThreshold();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
