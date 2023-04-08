// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IScriptyBuilder, WrappedScriptRequest} from "scripty/IScriptyBuilder.sol";
import {Base64} from "solady/utils/Base64.sol";
import {StringsUpgradeable as Strings} from "openzeppelin-upgradeable/utils/StringsUpgradeable.sol";

// import "forge-std/console.sol";

contract P5Render is OwnableUpgradeable, UUPSUpgradeable {

    address public constant ethfsFileStorageAddress = 0xFc7453dA7bF4d0c739C1c53da57b3636dAb0e11e;
    address public constant scriptyStorageAddress = 0x096451F43800f207FC32B4FF86F286EdaF736eE3;
    address public constant scriptyBuilderAddress  = 0x16b727a2Fc9322C724F4Bc562910c99a5edA5084;

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function tokenURI(uint256 tokenId, uint96 random, bytes memory script) public view returns (string memory) {
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
        requests[3].scriptContent = abi.encodePacked("var randomNr = ", Strings.toString(random), "; var tokenId = ", Strings.toString(tokenId), ";");

        //requests[3].name = "pointsAndLines";
        requests[4].wrapType = 0; // <script>[script]</script>
        requests[4].scriptContent = script;

        // For easier testing, bufferSize is injected in the constructor
        // of this contract.

        //requests[4].scriptContent = controllerScript;

        // For lazy devs that dont want to mess around with buffersize off-chain
        // calculate it here
        IScriptyBuilder scriptyBuilder = IScriptyBuilder(scriptyBuilderAddress);

        uint256 bufferSize = scriptyBuilder.getBufferSizeForHTMLWrapped(requests);

        bytes memory base64EncodedHTMLDataURI = IScriptyBuilder(scriptyBuilderAddress)
            .getEncodedHTMLWrapped(requests, bufferSize);

        bytes memory metadata = abi.encodePacked(
            '{"name":"p5.js Example - GZIP - Base64", "description":"Assembles GZIP compressed base64 encoded p5.js stored in ethfs FileStore contract with a demo scene. Metadata and animation URL are both base64 encoded.","animation_url":"',
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

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}