// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/P5Logic.sol";
import "../src/P5Render.sol";
import "solady/utils/ERC1967Factory.sol";
import {P5RenderProxy} from "../src/Proxies.sol";

contract CounterTest is Test {
    P5Logic logic;
    ERC1967Factory factory;
    address cloneDeploy;

    P5Render render;
    P5RenderProxy renderProxy; 
    P5Render wRender;

    bytes script = 'function setup() {createCanvas(720, 400); console.log("random: ", randomNr); console.log("tokenId: ", tokenId) }function draw() {  background(102);push();  translate(width * 0.2, height * 0.5);  rotate(frameCount / 200.0);  polygon(0, 0, 82, 3);  pop();  push();  translate(width * 0.5, height * 0.5);  rotate(frameCount / 50.0);  polygon(0, 0, 80, 20);pop();push();  translate(width * 0.8, height * 0.5); rotate(frameCount / -100.0); polygon(0, 0, 70, 7); pop();}function polygon(x, y, radius, npoints) {  let angle = TWO_PI / npoints; beginShape();for (let a = 0; a < TWO_PI; a += angle) {let sx = x + cos(a) * radius;   let sy = y + sin(a) * radius;    vertex(sx, sy);  }  endShape(CLOSE);}';

    function setUp() public {
        logic = new P5Logic();

        render = new P5Render();
        renderProxy = new P5RenderProxy(address(render), "");
        wRender = P5Render(address(renderProxy));
        wRender.initialize();

        factory = new ERC1967Factory();
    }

    function testClone() public {
        address clone = factory.deploy(address(logic), msg.sender); 
        P5Logic wClone = P5Logic(clone);
        //string memory _name, address _render, string memory _symbol, uint256 _maxSupply, uint256 _maxPerWallet, uint256 _pricePerNFT, bytes memory _script
        wClone.initialize("TestToken", address(wRender), "TEST", 100, 10, 0.01 ether, script);
        wClone.setMintStatus(2);
        wClone.mint{value: 0.01 ether}();
        console.log(wClone.tokenURI(1));
    }
}
