// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract P5RenderProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}