// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MockVotingToken} from "test/L10-Upgradability/MockVotingToken.sol";

contract VotingTokenTest is Test {
    MockVotingToken sut;
    uint256 deployerKey =
        0x1234567890123456789012345678901234567890123456789012345678901234;
    address public deployer = vm.addr(deployerKey);

    function setUp() public {
        vm.prank(deployer);
        sut = new MockVotingToken();
    }

    function testDeployement() public view {
        assertEq(
            sut.DEPLOYER_REWARD(),
            1_000_000 * 10 ** 18,
            "Deployer reward should be 1 million tokens"
        );
        assertEq(
            sut.totalSupply(),
            sut.DEPLOYER_REWARD(),
            "Total supply should be equal to deployer reward"
        );
        assertEq(
            sut.balanceOf(deployer),
            sut.DEPLOYER_REWARD(),
            "Deployer should have the total supply of tokens"
        );
    }

    function testDelegation() public {
        uint256 votingPower = sut.balanceOf(deployer);

        vm.startPrank(deployer);
        sut.delegateVotes();
        assertEq(
            sut.getVotes(deployer),
            votingPower,
            "Voting power should be equal to the balance of the deployer"
        );
        vm.stopPrank();
    }

    function testDelegateTo() public {
        address user = vm.addr(0x123);
        uint256 votingPower = sut.balanceOf(deployer);

        vm.startPrank(deployer);
        sut.delegateVotesTo(user);
        assertEq(
            sut.getVotes(user),
            votingPower,
            "Voting power of new user should be equal to the balance of the deployer"
        );
        vm.stopPrank();
    }

    function testDelegateWithSignature() public {
        uint256 expiry = block.timestamp + 1 days;
        vm.startPrank(deployer);
        address user = vm.addr(0x123);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            deployerKey,
            sut.hashedSignatureData(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
                        ),
                        user,
                        0,
                        expiry
                    )
                )
            )
        );

        sut.delegateBySig(user, 0, expiry, v, r, s);
        vm.stopPrank();

        assertEq(
            sut.getVotes(user),
            sut.balanceOf(deployer),
            "Voting power of new user should be equal to the balance of the deployer"
        );

        assertEq(
            sut.getVotes(deployer),
            0,
            "Voting power of deployer should be 0"
        );
    }
}
