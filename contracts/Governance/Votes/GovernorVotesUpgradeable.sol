// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../utils/IVotesUpgradeable.sol";

// For vote weight extraction from the IdentificationRegistryContract
abstract contract GovernorVotesUpgradeable is Initializable, GovernorUpgradeable {
    IVotesUpgradeable public token;

    function __GovernorVotes_init(IVotesUpgradeable tokenAddress) internal onlyInitializing {
        __GovernorVotes_init_unchained(tokenAddress);
    }

    function __GovernorVotes_init_unchained(IVotesUpgradeable tokenAddress) internal onlyInitializing {
        token = tokenAddress;
    }

     // Read the voting weight from the token's built in snapshot mechanism
    function _getVotes(uint256 tokenId, uint256 blockNumber) internal view virtual override returns (uint256) {
        return token.getPastVotes(tokenId, blockNumber);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}