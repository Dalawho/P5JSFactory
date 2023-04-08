// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/P5Logic.sol";
import "solady/utils/ERC1967Factory.sol";
import "solady/utils/ERC1967FactoryConstants.sol";
import {P5RenderProxy} from "../src/Proxies.sol";

contract P5LogicTest is Test {
    P5Logic logic;
    ERC1967Factory factory;
    address cloneDeploy;

    bytes script = 'function setup() {createCanvas(720, 400); console.log("random: ", randomNr); console.log("tokenId: ", tokenId) }function draw() {  background(102);push();  translate(width * 0.2, height * 0.5);  rotate(frameCount / 200.0);  polygon(0, 0, 82, 3);  pop();  push();  translate(width * 0.5, height * 0.5);  rotate(frameCount / 50.0);  polygon(0, 0, 80, 20);pop();push();  translate(width * 0.8, height * 0.5); rotate(frameCount / -100.0); polygon(0, 0, 70, 7); pop();}function polygon(x, y, radius, npoints) {  let angle = TWO_PI / npoints; beginShape();for (let a = 0; a < TWO_PI; a += angle) {let sx = x + cos(a) * radius;   let sy = y + sin(a) * radius;    vertex(sx, sy);  }  endShape(CLOSE);}';

    function setUp() public {
        logic = new P5Logic();
        factory = ERC1967Factory(ERC1967FactoryConstants.ADDRESS);
    }

    function testClone() public {
        address clone = factory.deploy(address(logic), msg.sender); 
        P5Logic wClone = P5Logic(clone);
        wClone.initialize("TestToken", "TEST", address(0), 100, 10, 0.01 ether, script);
        wClone.setMintStatus(2);
        wClone.mint{value: 0.01 ether}();
        //console.log(wClone.tokenURI(1));
    }

    // function testCloneAndCall() public {
    //     bytes memory data = abi.encodeWithSignature("initialize(string,string,address,uint256,uint256,uint256,bytes)", "TestToken", "TEST", address(this), 100, 10, 0.01 ether, script);
    //     address clone = factory.deployAndCall(address(logic), msg.sender, data); 
    //     P5Logic wClone = P5Logic(clone);
    //     //function initialize(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _maxPerWallet, uint256 _pricePerNFT, bytes memory _script) initializer public { 
    
    //     //wClone.initialize("TestToken", "TEST", 100, 10, 0.01 ether, script);
    //     wClone.setMintStatus(2);
    //     wClone.mint{value: 0.01 ether}();
    //     console.log(wClone.tokenURI(1));
    // }
}
