// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {TicketNFT} from "../src/TicketNFT.sol";

contract TicketNFTTest is Test {
    string constant NAME = "TicketNFT";
    string constant SYMBOL = "TICKET";
    TicketNFT public sut;

    function setUp() public {
        sut = new TicketNFT(NAME, SYMBOL);
    }

    function test_constructor() public view {
        assertEq(sut.name(), NAME);
        assertEq(sut.symbol(), SYMBOL);
        assertEq(sut.owner(), address(this));
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
