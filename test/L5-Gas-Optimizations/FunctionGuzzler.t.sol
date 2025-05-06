// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseFoundryTest} from "../BaseFoundryTest.sol";
import {FunctionGuzzler} from "src/L5-Gas-Optimizations/FunctionGuzzler.sol";

contract FunctionGuzzlerTest is BaseFoundryTest {
    FunctionGuzzler public sut;

    function setUp() public {
        sut = new FunctionGuzzler();
    }

    function addUsers(uint256 depositAmount) private {
        sut.registerUser();

        vm.startPrank(validUser);
        sut.registerUser();

        if (depositAmount > 0) {
            sut.deposit(depositAmount);
        }
        vm.stopPrank();

        for (uint256 i = 0; i < 100; i++) {
            (address user, ) = createUser(100);
            vm.startPrank(user);

            if (depositAmount > 0) {
                sut.deposit(depositAmount);
            }

            sut.registerUser();
            vm.stopPrank();
        }
    }

    function addValues() private {
        for (uint256 i = 0; i < 100; i++) {
            sut.addValue(i + 1);
        }
    }

    function testRegisterUsers() public {
        addUsers(0);
        assertTrue(sut.isRegistered(self));
    }

    function testAddValue() public {
        sut.registerUser();
        sut.addValue(10);
        assertEq(sut.totalValue(), 10);
    }

    function testSumValues() public {
        sut.registerUser();
        addValues();
        assertGt(sut.sumValues(), 0);
    }

    function testDeposit() public {
        sut.registerUser();
        sut.deposit(100);
        assertEq(sut.balances(self), 100);
    }

    function testFindUser() public {
        addUsers(0);
        assertTrue(sut.findUser(self));
    }

    function testTransfer() public {
        sut.registerUser();

        vm.startPrank(validUser);
        sut.registerUser();
        sut.deposit(1000);
        sut.transfer(self, 100);
        vm.stopPrank();

        assertEq(sut.balances(self), 100);
        assertEq(sut.balances(validUser), 900);
    }

    function testAverageValue() public {
        sut.registerUser();
        addValues();

        uint256 average = sut.getAverageValue();
        assertGt(average, 0);
    }
}
