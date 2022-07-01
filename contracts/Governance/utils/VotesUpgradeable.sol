// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/CheckpointsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IVotesUpgradeable.sol";

abstract contract VotesUpgradeable is Initializable, IVotesUpgradeable {
    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;

    //maps tokenid -> tokenId chose to delegate
    mapping(uint256 => uint256) private _delegation;
    //maps tokensIds that has delegated to a tokenId
    mapping(uint256 => uint256[]) private _delegators;
    // Mapping from token ID to another mapping from the _delegated to the index of it in the _delegated[] array
    mapping(uint256 => mapping(uint256 => uint256)) private _delegatorIndex;
    // token Id -> vote weight per block number
    mapping(uint256 => CheckpointsUpgradeable.History) private _delegateCheckpoints;
    //total vote supply, historic by block number
    CheckpointsUpgradeable.History private _totalCheckpoints;


    function __Votes_init() internal onlyInitializing {
    }

    function __Votes_init_unchained() internal onlyInitializing {
    }

    //Returns the current amount of votes that `tokenId` has.
    function getVotes(uint256 tokenId) public view virtual override returns (uint256) {
        return _delegateCheckpoints[tokenId].latest();
    }

    //Returns the amount of votes a tokenId had in a specific blockNumber
    function getPastVotes(uint tokenId, uint256 blockNumber) public view virtual override returns (uint256) {
        return _delegateCheckpoints[tokenId].getAtBlock(blockNumber-1);
    }

    // total voting power at a certain block
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _totalCheckpoints.getAtBlock(blockNumber);
    }

    // total voting power
    function getTotalSupply() public view virtual returns (uint256) {
        return _totalCheckpoints.latest();
    }

    // Returns all the tokens ids that have delegated to 'tokenId'
    function getDelegatedIdsForTokenId(uint256 tokenId) public view returns (uint256[] memory){
        return _delegators[tokenId];
    }

    // Return the tokenId 'tokenId' has chosen to delegate
    function delegates(uint256 tokenId) public view virtual override returns (uint256) {
        return _delegation[tokenId];
    }

    //delegate from 'tokenId' to delegatee
    function delegate(uint256 tokenId, uint256 delegatee) public virtual {
        require(delegates(tokenId) != delegatee, "VotesUpgradeable: Already delegated to this tokenId");
        if(tokenId != delegatee) {
            require(delegates(delegatee) == delegatee, "VotesUpgradeable: Delegatee has already delegated");
        }

        // can have vote already delegated, hence votingUnit will be 0
        uint256 votingUnits = getVotes(tokenId) == 0 ? 1 : getVotes(tokenId);

        //return all delegated votes if it have votes delegated to him before delegating
        uint256[] memory delegated = _delegators[tokenId];
        _returnDelegate(delegated, tokenId);

        _delegate(tokenId, delegatee, votingUnits);
    }

    // delegate from 'tokenId' to delegatee
    function _delegate(uint256 tokenId, uint256 delegatee, uint256 votingUnits) internal virtual {
        // change the delegatee, eliminate from the oldDelegate delegators array
        uint256 oldDelegate = delegates(tokenId);
        _delegation[tokenId] = delegatee;
        _deleteTokenIdFromDelegatorArray(oldDelegate, tokenId);

        //Delete delegators from 'tokenId'
        delete _delegators[tokenId];
        // update delegator index map & add delegators to 'delegatee'
        _delegatorIndex[delegatee][tokenId] = _delegators[delegatee].length;
        _delegators[delegatee].push(tokenId);

        emit DelegateChanged(tokenId, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, votingUnits);
    }

    // return delegated votes to their respective token
    function _returnDelegate(uint256[] memory array, uint256 oldDelegatee) internal {
        if(array.length > 1) {
            for (uint i = 0 ; i < array.length; i++) {
                // array[i] = tokenId who have its vote delegated to oldDelegatee
                if(array[i] == oldDelegatee){
                    delete array[i];
                }
                // Delegator delegates back to himself
                _delegation[array[i]] = array[i];
                // Return voting weight to delegator
                _delegateCheckpoints[array[i]].push(_add, 1);
                // Add himself to the array of tokens that have delegated to him
                _delegators[array[i]].push(array[i]);

                emit DelegateChanged(array[i], oldDelegatee, array[i]);
                emit DelegateVotesChanged(array[i], 0, 1);

                delete array[i];
            }
        }
    }

    // delete `tokenIdToRemove` from `tokenId`_delegators array
    function _deleteTokenIdFromDelegatorArray(uint256 tokenId, uint256 tokenIdToRemove) internal {
        if(tokenId != tokenIdToRemove) {
            uint256 lastTokenIndex = _delegators[tokenId].length - 1;
            uint256 tokenIndex = _delegatorIndex[tokenId][tokenIdToRemove];
            // When the token to delete is the last token, the swap operation is unnecessary
            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = _delegators[tokenId][lastTokenIndex];
                _delegators[tokenId][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
                _delegatorIndex[tokenId][lastTokenId] = tokenIndex; // Update the moved token's index
            }
            delete _delegatorIndex[tokenId][tokenIdToRemove];
            _delegators[tokenId].pop();
        }
    }

    function _afterBurn(
        uint256 tokenId
    ) internal virtual
    {
        // remove delegation
        uint256 oldDelegate = _delegation[tokenId];
        _delegateCheckpoints[oldDelegate].push(_subtract, 1);
        _deleteTokenIdFromDelegatorArray(oldDelegate, tokenId);

        // return delegations
        uint256[] memory delegated = _delegators[tokenId];
        _returnDelegate(delegated, tokenId);

        // delete checkpoints & maps
        delete _delegateCheckpoints[tokenId];
        delete _delegation[tokenId];
        delete _delegators[tokenId];

        //subtract 1 vote form total supply
        _totalCheckpoints.push(_subtract, 1);
        emit DelegateRemoved(tokenId);
    }


    function _afterMint(
        uint256 tokenId
    ) internal virtual
    {
        // delegate to himself
        _delegation[tokenId] = tokenId;
        _delegateCheckpoints[tokenId].push(_add, 1);
        _delegators[tokenId].push(tokenId);
        _totalCheckpoints.push(_add, 1);
        emit DelegateCreated(tokenId);
    }

    function _moveDelegateVotes(
        uint256 from,
        uint256 to,
        uint256 amount
    ) private {
        if (from != to && amount > 0) {
            // substract all voting units when delegating
            (uint256 oldValueFrom, uint256 newValueFrom) = _delegateCheckpoints[from].push(_subtract, amount);
            emit DelegateVotesChanged(from, oldValueFrom, newValueFrom);

            // Always add 1 -> just can delegate your own vote
            (uint256 oldValueTo, uint256 newValueTo) = _delegateCheckpoints[to].push(_add, 1);
            emit DelegateVotesChanged(to, oldValueTo, newValueTo);
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    // Implemented in ERC721Votes
    function _getVotingUnits(uint256) internal view virtual returns (uint256);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

