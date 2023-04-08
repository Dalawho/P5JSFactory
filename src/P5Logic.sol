// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProofUpgradeable} from "openzeppelin-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import { SSTORE2 } from "solmate/utils/SSTORE2.sol";
import {IScriptyBuilder, WrappedScriptRequest} from "scripty/IScriptyBuilder.sol";
import {Base64} from "solady/utils/Base64.sol";
import {StringsUpgradeable as Strings} from "openzeppelin-upgradeable/utils/StringsUpgradeable.sol";


contract P5Logic is Initializable, ERC721, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable{

    address public constant ethfsFileStorageAddress = 0xFc7453dA7bF4d0c739C1c53da57b3636dAb0e11e;
    address public constant scriptyStorageAddress = 0x096451F43800f207FC32B4FF86F286EdaF736eE3;
    address public constant scriptyBuilderAddress  = 0x16b727a2Fc9322C724F4Bc562910c99a5edA5084;

    bytes32 public ALRoot;
    uint256 public mintStatus; 
    address public mintReciever;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public pricePerNFT;
    address public script;

    error PublicMintNotStarted();
    error PayMintPrice();
    error ALMintNotStarted();
    error NotOnAL();
    error MaxSupplyMinted();
    error AlreadyMintedAllowance();
    error SplitterNotSet();

    //Constructor / Initializer

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _maxPerWallet, uint256 _pricePerNFT, bytes memory _script) initializer public { 
        __ERC721_init(_name, _symbol, 1);
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        mintReciever = msg.sender;
        maxSupply = _maxSupply;
        maxPerWallet = _maxPerWallet;
        pricePerNFT = _pricePerNFT;
        script = SSTORE2.write(_script);
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
        WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](5);
        requests[0].name = "scriptyBase";
        requests[0].wrapType = 0; // <script>[script]</script>
        requests[0].contractAddress = scriptyStorageAddress;

        requests[1].name = "p5-v1.5.0.min.js.gz";
        requests[1].wrapType = 2; // <script type="text/javascript+gzip" src="data:text/javascript;base64,[script]"></script>
        requests[1].contractAddress = ethfsFileStorageAddress;

        requests[2].name = "gunzipScripts-0.0.1.js";
        requests[2].wrapType = 1; // <script src="data:text/javascript;base64,[script]"></script>
        requests[2].contractAddress = ethfsFileStorageAddress;

        requests[3].wrapType = 0; // <script>[script]</script>
        requests[3].scriptContent = abi.encodePacked("var randomNr = ", Strings.toString(_ownerOf[tokenId].random), "; var tokenId = ", Strings.toString(tokenId), ";");

        requests[4].wrapType = 0; // <script>[script]</script>
        requests[4].scriptContent = SSTORE2.read(script);

        // For lazy devs that dont want to mess around with buffersize off-chain
        // calculate it here
        IScriptyBuilder scriptyBuilder = IScriptyBuilder(scriptyBuilderAddress);

        uint256 bufferSize = scriptyBuilder.getBufferSizeForHTMLWrapped(requests);

        bytes memory base64EncodedHTMLDataURI = IScriptyBuilder(scriptyBuilderAddress)
            .getEncodedHTMLWrapped(requests, bufferSize);

        bytes memory metadata = abi.encodePacked(
            '{"name":"p5.js Clone Example", "description":"A cloned contract for cheap p5js deployments.","animation_url":"',
            base64EncodedHTMLDataURI,
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );    
    }

    //
    function withdraw() external onlyOwner {
        if(mintReciever == address(0)) revert SplitterNotSet();
        payable(mintReciever).transfer(address(this).balance); //should I change this? 
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