// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {VotingLogicV2} from "src/L10-Upgradability/VotingLogicV2.sol";
import {MockVotingToken} from "test/L10-Upgradability/MockVotingToken.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransientDeployer} from "src/L10-Upgradability/TransientDeployer.sol";

contract VotingLogicV1Test is Test {
    VotingLogicV2 sut;
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
            address(new VotingLogicV2())
        );

        sut = VotingLogicV2(proxy);
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

    function testExecuteProposalShouldRevert() public {
        uint256 proposalId = sut.createProposal("Test Proposal");

        vm.startPrank(user);
        token.delegateVotes();
        sut.vote(proposalId, false);
        vm.stopPrank();

        vm.expectRevert(VotingLogicV2.QuoromNotReached.selector);
        sut.executeProposal(proposalId);
    }
}
