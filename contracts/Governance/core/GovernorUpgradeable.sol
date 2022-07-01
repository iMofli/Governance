// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/TimersUpgradeable.sol";
import "./IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


abstract contract GovernorUpgradeable is Initializable, IGovernorUpgradeable {
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    struct ProposalCore {
        TimersUpgradeable.BlockNumber voteStart;
        TimersUpgradeable.BlockNumber voteEnd;
    }

    string private _name;
    //mapping from proposalId to ProposalCore
    mapping(uint256 => ProposalCore) private _proposals;

    function __Governor_init(string memory name_) internal onlyInitializing {
        __Governor_init_unchained(name_);
    }

    function __Governor_init_unchained(string memory name_) internal onlyInitializing {
        _name = name_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function hashProposal(
        uint256 blockNumber,
        uint256 tokenId,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(blockNumber, tokenId, descriptionHash)));
    }

    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if(!_quorumReached(proposalId)) {
            return ProposalState.QuorumNotReached;
        }
        if (_voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    // returns proposal start block
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    // returns proposal end block
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    // overridden in GovernorSettings
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    // Whether or not the required number of votes has been obtained in `proposalId`
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    // Whether the `proposalId` succeeded or not
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    function _hasVoted(uint256 proposalId, address account) internal view virtual returns (bool);

    // Get the voting weight of a tokenId at a specific blockNumber
    function _getVotes(
        uint256 tokenId,
        uint256 blockNumber
    ) internal view virtual returns (uint256);

    // Register a vote with a given support and voting weight.
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;

    function propose(
        string memory description,
        uint256 tokenId
    ) public virtual override returns (uint256) {
        require(
            getVotes(tokenId, block.number - 1 ) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(uint256(block.number), tokenId, keccak256(bytes(description)));

        //creates proposal checks if it already exists
        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        // sets snapshot block (start block) & deadline (endblock)
        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            tokenId,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    function hasVoted(uint256 proposalId, uint256 tokenId) external view virtual override returns (bool) {
        address tokenIdAddress = _parseTokenIdToAddress(tokenId);
        return _hasVoted(proposalId, tokenIdAddress);
    }

    function _parseTokenIdToAddress(uint256 tokenId) public pure returns (address) {
        return address(uint160(bytes20(keccak256(abi.encode(tokenId)))));
    }

    function getVotes(uint256 tokenId, uint256 blockNumber) public view virtual override returns (uint256) {
        return _getVotes(tokenId, blockNumber);
    }

    function castVote(uint256 proposalId, uint8 support, uint256 tokenId) public virtual override returns (uint256 balance) {
        address voter = _parseTokenIdToAddress(tokenId);
        return _castVote(proposalId, voter, support, tokenId);
    }


    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 tokenId
    ) internal virtual returns (uint256) {
        // retrieve proposal, check if is active
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        // get votes -> call to ERC721 to get vote weight & count vote
        uint256 weight = getVotes(tokenId, proposal.voteStart.getDeadline());
        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight);

        return weight;
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
