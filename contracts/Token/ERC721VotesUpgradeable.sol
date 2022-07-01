// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../Governance/utils/VotesUpgradeable.sol";

abstract contract ERC721VotesUpgradeable is Initializable, ERC721Upgradeable, VotesUpgradeable {

    function __ERC721Votes_init() internal onlyInitializing {
    }

    function __ERC721Votes_init_unchained() internal onlyInitializing {
    }

    function delegate(uint256 tokenId, uint256 delegatee) public virtual override {
        require(ownerOf(tokenId) == msg.sender, "VotesUpgradeable: Wallet not owner of the tokenId");
        super.delegate(tokenId, delegatee);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if(to == address(0)) {
            _afterBurn(tokenId);
        }
        if(from == address(0)) {
            _afterMint(tokenId);
        }
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _afterMint(
        uint256 tokenId
    ) internal virtual override {
        super._afterMint(tokenId);
    }

    function _afterBurn(
        uint256 tokenId
    ) internal virtual override {
        super._afterBurn(tokenId);
    }

    function _getVotingUnits(uint256 tokenId) internal view virtual override returns (uint256) {
        return super.getVotes(tokenId);
    }

    function getPastVotes(uint256 tokenId, uint256 blockNumber) public view override returns (uint256) {
        require(ownerOf(tokenId) == tx.origin, "ERC721Upgradeable: Address not owner of the token");
        return super.getPastVotes(tokenId, blockNumber);
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
