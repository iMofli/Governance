// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract IdentificationRegistryContract is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, ERC721VotesUpgradeable {

    bytes32 public merkleRoot;
    string public ipfsHash;

    modifier isValidMerkleProof(
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) {
        require(MerkleProofUpgradeable.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender, tokenId))),
            "AccessControllerUpgradeable: Address-ID Not In Whitelist");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        bytes32 _merkleRoot,
        string memory _ipfsHash
    ) initializer public {
        __ERC721_init(name, symbol);
        __EIP712_init(name, "1");
        __Ownable_init();
        _setMerkleRoot(_merkleRoot);
        _setIpfsHash(_ipfsHash);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setMerkleRoot(
        bytes32 _merkleRoot
    ) internal {
        merkleRoot = _merkleRoot;
    }

    function _setIpfsHash(
        string memory _ipfsHash
    ) internal  {
        ipfsHash = _ipfsHash;
    }

    function whiteListMint(
        uint256 tokenId,
        bytes32[] calldata _merkleProof
    ) public isValidMerkleProof(tokenId, _merkleProof) {
        require(!_exists(tokenId), "Address Already Claimed ID");
        _safeMint(msg.sender, tokenId);
    }

    function updateCensus(
        uint256 tokenId,
        bytes32 _merkleRoot,
        string memory _ipfsHash
    ) external {
        _setMerkleRoot(_merkleRoot);
        _setIpfsHash(_ipfsHash);
        if(tokenId != 0 && _exists(tokenId)) {
            _burn(tokenId);
        }
    }

    function _safeMint(
        address to,
        uint256  tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721VotesUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId);
    }
}