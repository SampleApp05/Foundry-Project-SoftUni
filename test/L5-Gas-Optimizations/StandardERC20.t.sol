// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {BaseFoundryTest} from "../BaseFoundryTest.sol";
import {StandardERC20} from "src/L5-Gas-Optimizations/StandardERC20.sol";

contract StandardERC20Tests is BaseFoundryTest {
    StandardERC20 public sut;

    function setUp() public {
        sut = new StandardERC20("Normal", "NTR", 18, 1000 ether);
    }

    function testTransfer() public {
        sut.transfer(validUser, 100 ether);
        assertEq(sut.balanceOf(validUser), 100 ether);
        assertEq(sut.balanceOf(self), 900 ether);
    }

    function testTransferFrom() public {
        sut.approve(validUser, 100 ether);
        vm.startPrank(validUser);
        sut.transferFrom(self, owner, 100 ether);
        vm.stopPrank();

        assertEq(sut.balanceOf(owner), 100 ether);
        assertEq(sut.balanceOf(self), 900 ether);
    }

    function testApprove() public {
        sut.approve(validUser, 100 ether);
        assertEq(sut.allowance(self, validUser), 100 ether);
    }
}
