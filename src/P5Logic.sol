// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProofUpgradeable} from "openzeppelin-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

contract P5Logic is Initializable, ERC721, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable{

    event CombinationMinted(uint8 indexed composition, uint8 indexed palette);

    bytes32 public ALRoot;
    uint256 public mintStatus; 
    address public mintReciever;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public pricePerNFT;

    error PublicMintNotStarted();
    error PayMintPrice();
    error ALMintNotStarted();
    error NotOnAL();
    error MaxSupplyMinted();
    error NoContracts();
    error DoNotMintOriginals();
    error OnlyCombineOriginals();
    error ScrambleAlreadyMinted();
    error AlreadyMintedAllowance();
    error MaxLimitPerComposition();
    error SplitterNotSet();

    //Constructor / Initializer

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol) initializer public { 
        __ERC721_init(name, symbol, 1);
        __Ownable_init();
        __DefaultOperatorFilterer_init();
    }

    /// Admin setters
    
    function setMintStatus(uint256 _newStatus) external onlyOwner {
        mintStatus = _newStatus;
    }

    function setALRoot(bytes32 _newRoot) external onlyOwner {
        ALRoot = _newRoot;
    }

    function setMintReciever(address _mintReciever) external onlyOwner {
        mintReciever = _mintReciever;
    }

    /// Mint function

    function mint() public payable {
        if(mintStatus != 2) revert PublicMintNotStarted();
        _mintToken();
    }

    function allowlistMint(bytes32[] calldata _proof) public payable {
        if(mintStatus < 1) revert ALMintNotStarted();
        verify(_proof, msg.sender, ALRoot);
        _mintToken();
    }

    function _mintToken() internal {
        if(msg.value != pricePerNFT) revert PayMintPrice();
        if(_balanceOf[msg.sender].minted + 1 > maxPerWallet) revert AlreadyMintedAllowance();
        if(totalSupply() + 1 > maxSupply) revert MaxSupplyMinted();
        
        _mint(msg.sender);
    }

    //Helper functions

    function amountMinted(address _user) public view returns(uint16) {
        return _balanceOf[_user].minted;
    }
    
    function verify(
        bytes32[] memory proof,
        address addr,
        bytes32 _root
    ) internal pure {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
        require(MerkleProofUpgradeable.verify(proof, _root, leaf), "Invalid proof");
    }

    //TokenURI
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if(tokenId == 0 || tokenId > tokenIndex) revert();
        return "sd";//render.tokenURI(tokenId, _ownerOf[tokenId].compositionId, _ownerOf[tokenId].paletteId);
    }

    //
    function withdraw() external onlyOwner {
        if(mintReciever == address(0)) revert SplitterNotSet();
        payable(mintReciever).transfer(address(this).balance); //should I change this? 
    }

    function contractURI() public view returns (string memory) {
        //return getContractInfo();
        //write something here
    }

    //////////////////////// Operatorfilter overrides ////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from,
        address to,
        uint256 id) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom( address from,
        address to,
        uint256 id,
        bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, data);
    }
}