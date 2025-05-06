// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BaseFoundryTest} from "../BaseFoundryTest.sol";
import {StakingContract} from "src/L5-Gas-Optimizations/StakingContract.sol";
import {StandardERC20_OP} from "src/L5-Gas-Optimizations/StandardERC20_OP.sol";

contract StakingContractTests is BaseFoundryTest {
    StandardERC20_OP public token;
    StakingContract public sut;

    function setUp() public {
        token = new StandardERC20_OP("Token", "TT", 18, 1_000_000 ether);
        sut = new StakingContract(address(token));

        token.transfer(validUser, 100 ether);
    }

    function addStakers(uint8 count) public {
        for (uint8 i = 0; i < count; ) {
            (address user, ) = createUser(10);
            token.transfer(user, 1 ether);

            vm.startPrank(user);
            sut.stake(1 ether);
            vm.stopPrank();

            unchecked {
                i++;
            }
        }

        vm.startPrank(validUser);
        sut.stake(10 ether);
        vm.stopPrank();
    }

    function testStake() public {
        uint256 stakeAmount = 100 ether;

        vm.startPrank(validUser);
        sut.stake(stakeAmount);
        (uint256 stakedAmount, , ) = sut.userInfo(validUser);
        vm.stopPrank();

        assertEq(stakedAmount, stakeAmount);
        assertEq(token.balanceOf(validUser), 100 ether - stakeAmount);
    }

    function testWithdrawal() public {
        uint256 stakeAmount = 100 ether;
        sut.stake(stakeAmount);

        mineMultiple(20);
        sut.withdraw(stakeAmount);
        (uint256 stakedAmount, , ) = sut.userInfo(self);
        assertEq(stakedAmount, 0);
    }

    function testClaimRewards() public {
        uint256 stakeAmount = 100 ether;
        sut.stake(stakeAmount);

        mineMultiple(20);

        uint256 pendingRewards = sut.pendingReward(self);
        uint256 balance = token.balanceOf(self);

        sut.claimReward();
        (uint256 stakedAmount, , uint256 rewardsAccumulated) = sut.userInfo(
            self
        );
        assertEq(stakedAmount, stakeAmount);
        assertEq(rewardsAccumulated, 0);
        assertEq(token.balanceOf(self), balance + pendingRewards);
    }

    function testUpdateAllRewards() public {
        uint8 stakers = 50;

        addStakers(stakers);
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();
        mineMultiple(20);
        sut.updateAllRewards();

        assertGt(sut.pendingReward(validUser), 0);

        for (uint8 i = 0; i < stakers; ) {
            address user = customUsers[i + 10];
            console.log("User: ", user);
            assertGt(sut.pendingReward(user), 0);
            unchecked {
                i++;
            }
        }
    }
}
