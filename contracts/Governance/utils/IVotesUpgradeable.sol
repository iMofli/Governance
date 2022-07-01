// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotesUpgradeable {
    // Emitted when a tokenId changes their delegate.
    event DelegateChanged(uint256 indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    // Emitted when a token delegate change results in changes to a delegate's number of votes.
    event DelegateVotesChanged(uint256 indexed delegate, uint256 previousBalance, uint256 newBalance);

    // Emitted when a token is burned, so the delegated votes are lost
    event DelegateRemoved(uint256 indexed tokenId);

    // Emitted when a token is minted, so the delegated votes are created
    event DelegateCreated(uint256 indexed tokenId);

    function getVotes(uint256 tokenId) external view returns (uint256);

    function getPastVotes(uint256 tokenId, uint256 blockNumber) external view returns (uint256);

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    function delegates(uint256 tokenId) external view returns (uint256);
}