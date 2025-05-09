// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {Test, console} from "forge-std/Test.sol";
import {TransientDeployer} from "src/L10-Upgradability/TransientDeployer.sol";
import {VotingToken} from "src/L10-Upgradability/VotingToken.sol";
import {VotingLogicV1} from "src/L10-Upgradability/VotingLogicV1.sol";
import {VotingLogicV2} from "src/L10-Upgradability/VotingLogicV2.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TransparantProxyTest is Test {
    error CouldNotTransferEther();
    error ProxyAlreadyDeployed();

    VotingToken tokenContract;
    // VotingLogicV1 logicContractV1;
    // VotingLogicV2 logicContractV2;

    address sut;
    address public adminAddress = vm.addr(0x66261);
    address public owner = vm.addr(0x6661);
    address public user = vm.addr(0x354235);
    VotingToken public token;
    ProxyAdmin public proxyAdmin;
    TransientDeployer public deployerContract;

    function setUp() public {
        deployerContract = new TransientDeployer();
        vm.startPrank(owner);
        token = new VotingToken();
        proxyAdmin = new ProxyAdmin(adminAddress);

        token.transfer(user, 100 * 10 ** 18); // Transfer 100 tokens to the user
        vm.stopPrank();

        sut = deployerContract.deployProxy(
            address(token),
            address(proxyAdmin),
            owner,
            address(new VotingLogicV1())
        );
    }

    function testV1Logic() public {
        VotingLogicV1 logicProxy = VotingLogicV1(sut);
        assertEq(logicProxy.owner(), owner);
        assertEq(address(logicProxy.votingToken()), address(token));

        uint256 proposalId = logicProxy.createProposal("Test Proposal");

        vm.startPrank(user);
        tokenContract.delegateVotes();
        logicProxy.vote(proposalId, false);
        vm.stopPrank();

        bool executed = logicProxy.executeProposal(proposalId);
        assertFalse(executed, "Proposal should not be executed yet");
    }

    function testV2Upgrade() public {
        VotingLogicV1 logicProxy = VotingLogicV1(sut);
        VotingLogicV2 logicV2 = new VotingLogicV2();

        uint256 proposalId = logicProxy.createProposal("Test Proposal");

        vm.startPrank(user);
        tokenContract.delegateVotes();
        logicProxy.vote(proposalId, false); // vote
        vm.stopPrank();

        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(sut);

        vm.startPrank(adminAddress);
        proxyAdmin.upgradeAndCall(
            proxy,
            address(logicV2),
            abi.encodePacked("") // No initialization needed
        );

        VotingLogicV2 logicProxyV2 = VotingLogicV2(sut);

        assertEq(logicProxyV2.owner(), owner);
        assertEq(address(logicProxyV2.votingToken()), address(token));

        uint256 votingPower = logicProxyV2.getUserVotingPower(user);
        assertEq(votingPower, 100 * 10 ** 18, "User should have 100 votes");

        (uint256 votesFor, uint256 votesAgainst) = logicProxyV2
            .getProposalVotes(proposalId);
        assertEq(
            votesAgainst,
            votingPower,
            "Against Votes should be equal to user voting power"
        );

        vm.expectRevert(VotingLogicV2.QuoromNotReached.selector);
        logicProxyV2.executeProposal(proposalId);

        vm.prank(owner);
        tokenContract.delegateVotes();

        assertTrue(
            logicProxyV2.executeProposal(proposalId),
            "Proposal should be executed"
        );
    }
}
