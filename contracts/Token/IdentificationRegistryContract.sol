// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract IdentificationRegistryContract is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721VotesUpgradeable, OwnableUpgradeable {

    bytes32 public merkleRoot;
    string public ipfsHash;

    event UpdateCensus(uint256 indexed from, bytes32 indexed merkleTree, string ipfsHash);

    modifier isValidMerkleProof(
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) {
        require(MerkleProofUpgradeable.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender, tokenId))),
            "IdentificationRegistryContract: Address-ID Not In Whitelist");
        _;
    }

    function whiteListMint(
        uint256 tokenId,
        bytes32[] calldata _merkleProof
    ) public isValidMerkleProof(tokenId, _merkleProof) {
        require(!_exists(tokenId), "IdentificationRegistryContract: TokenId Already Claimed");
        _safeMint(msg.sender, tokenId);
    }

    function initialize(
        string memory name,
        string memory symbol,
        bytes32 _merkleRoot,
        string memory _ipfsHash
    ) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Votes_init();
        __ERC721Enumerable_init();
        __Ownable_init();
        _setMerkleRoot(_merkleRoot);
        _setIpfsHash(_ipfsHash);
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

    function updateCensus(
        uint256 tokenId,
        bytes32 _merkleRoot,
        string memory _ipfsHash
    ) external onlyOwner {
        _setMerkleRoot(_merkleRoot);
        _setIpfsHash(_ipfsHash);
        if(tokenId != 0 && _exists(tokenId)) {
            _burn(tokenId);
        }

        emit UpdateCensus(tokenId, _merkleRoot, _ipfsHash);

    }

    // Return the tokenID at the specific index if it has delegated to himself, 0 otherwise
    function getDelegateeByIndex(uint256 index) external view returns(uint256) {
        uint256 tokenId = tokenByIndex(index);
        uint256 delegate = delegates(tokenId);
        if(tokenId == delegate) {
            return tokenId;
        }
        return 0;
    }

    // Following functions are overrides required to inherit ERC721 from OZ

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


    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}