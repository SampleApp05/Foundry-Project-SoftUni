// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {VotingLogicV1} from "src/L10-Upgradability/VotingLogicV1.sol";
import {MockVotingToken} from "test/L10-Upgradability/MockVotingToken.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransientDeployer} from "src/L10-Upgradability/TransientDeployer.sol";

contract VotingLogicV1Test is Test {
    VotingLogicV1 sut;
    address public owner = vm.addr(0x6661);
    address public user = vm.addr(0x354235);
    MockVotingToken public token;
    ProxyAdmin public proxyAdmin;
    TransientDeployer public deployerContract;

    function setUp() public {
        deployerContract = new TransientDeployer();
        vm.startPrank(owner);
        token = new MockVotingToken();
        proxyAdmin = new ProxyAdmin(owner);

        token.transfer(user, 100 * 10 ** 18); // Transfer 100 tokens to the user
        vm.stopPrank();

        address proxy = deployerContract.deployProxy(
            address(token),
            address(proxyAdmin),
            owner,
            address(new VotingLogicV1())
        );

        sut = VotingLogicV1(proxy);
    }

    function testCreateProposal() public {
        vm.startPrank(user);

        uint256 proposalId = sut.createProposal("Test Proposal");
        assertEq(proposalId, 0, "Proposal ID should be 0");
        assertEq(sut.currentProposalId(), 1, "Current proposal ID should be 1");

        (
            ,
            address proposer,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed
        ) = sut.proposals(proposalId);

        assertEq(user, proposer, "Proposer should match the user address");
        assertEq(description, "Test Proposal", "Description should match");
        assertEq(forVotes, 0, "For votes should be 0");
        assertEq(againstVotes, 0, "Against votes should be 0");
        assertFalse(executed, "Proposal should not be executed yet");

        vm.stopPrank();
    }

    function testGetUserVotingPower() public {
        vm.prank(user);
        token.delegateVotes(); // Delegate votes to the user for voting power

        uint256 votingPower = sut.getUserVotingPower(user);
        uint256 invalidUserPower = sut.getUserVotingPower(address(0x2525));

        assertEq(
            votingPower,
            100 * 10 ** 18,
            "User voting power should be 1000 tokens"
        );

        assertEq(
            invalidUserPower,
            0,
            "Invalid user should have 0 voting power"
        );
    }

    function testVote() public {
        uint256 proposalId = sut.createProposal("Test Proposal");

        vm.startPrank(owner);
        token.delegateVotes();
        sut.vote(proposalId, true);
        vm.stopPrank();

        vm.startPrank(user);
        token.delegateVotes();
        sut.vote(proposalId, false);
        vm.stopPrank();

        (, , , uint256 forVotes, uint256 againstVotes, ) = sut.proposals(
            proposalId
        );

        assertEq(
            forVotes,
            sut.getUserVotingPower(owner),
            "For votes should match"
        );
        assertEq(
            againstVotes,
            sut.getUserVotingPower(user),
            "Against votes should match"
        );
    }

    function testExecuteProposal() public {
        uint256 proposalId = sut.createProposal("Test Proposal");

        vm.startPrank(owner);
        token.delegateVotes();
        sut.vote(proposalId, true);
        vm.stopPrank();

        vm.startPrank(user);
        token.delegateVotes();
        sut.vote(proposalId, false);
        vm.stopPrank();

        bool executed = sut.executeProposal(proposalId);

        assertTrue(executed, "Proposal should be executed successfully");
    }
}
