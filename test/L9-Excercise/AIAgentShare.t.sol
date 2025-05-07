// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {AIAgentShare} from "src/L9-Excercise/AIAgentShareToken.sol";
import {MockAIAgentShare} from "./MockAIAgenShareToken.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AIAgentShareTests is Test {
    event Purchase(address indexed buyer);
    event DelegatedPurchase(address indexed authorizer, address indexed target);
    event FundingRoundFinilized();

    uint256 primaryUserKey;
    address primaryUser;
    address invalidUser;
    address relayer;

    uint256 fundingAmount = 5_000_000 * 10 ** 18;
    bytes32 whitelistHash =
        0x2eacf52fc1f9971fdfc90b7ec53c0288092cdfb40dbda0d1aba745bab4602b86;
    uint256 expirationDate = block.timestamp + 30 days;

    bytes32 proofOne =
        0xc0be44690b9e117fa3d8b033eb7387650636fcdad0a7da67ebcd47714fa4ffa4;
    bytes32 proofTwo =
        0x2a5716d7f9230f3af29aa0f0bd9f46269dc6cfa7f2563285110e578f8ee91ff5;
    bytes32 proofThree =
        0xef3cf548c1f92cc9cb2d9e101ce75b3831b23b962a75874ed20c0cdaea8b40e6;
    bytes32 proofFour =
        0x2c86fb270ad088f004976404363a0b688a35d227442f7b02b1fd10a8c951f2f6;

    bytes32[] proof = [proofOne, proofTwo, proofThree, proofFour];

    MockAIAgentShare sut;

    function setUp() public {
        primaryUserKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        primaryUser = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        invalidUser = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        relayer = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        sut = new MockAIAgentShare(
            address(this),
            fundingAmount,
            relayer,
            whitelistHash,
            expirationDate
        );
    }

    function testDeployment() public view {
        assertEq(sut.owner(), address(this));
        assertEq(sut.fundingAmount(), fundingAmount);
        assertEq(sut.relayer(), relayer);
        assertEq(sut.whitelistedParticipantsHash(), whitelistHash);
        assertEq(sut.expirationDate(), expirationDate);
    }

    function testValidateSignature() public {
        uint256 amount = 10 ether;
        bytes32 nonce = keccak256("testNonce");
        uint256 validAfter = block.timestamp;
        uint256 expiration = block.timestamp + 1 days;

        bytes32 dataHash = keccak256(
            abi.encode(
                sut.DELEGATE_PURCHASE_TYPE_HASH(),
                primaryUser,
                relayer,
                amount,
                validAfter,
                expiration,
                nonce
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            primaryUserKey,
            sut.hashedSignatureData(dataHash)
        );

        vm.warp(block.timestamp + 90 seconds);
        assertTrue(
            sut.mockValidateSignature(
                sut.DELEGATE_PURCHASE_TYPE_HASH(),
                primaryUser,
                relayer,
                amount,
                validAfter,
                expiration,
                nonce,
                v,
                r,
                s
            ),
            "Signature should be valid"
        );
    }

    function testValidateSignatureWithInvalidUser() public {
        uint256 validAfter = block.timestamp;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            primaryUserKey,
            sut.hashedSignatureData(
                keccak256(
                    abi.encode(
                        sut.DELEGATE_PURCHASE_TYPE_HASH(),
                        primaryUser,
                        relayer,
                        10 ether,
                        validAfter,
                        validAfter + 1 days,
                        keccak256("testNonce2")
                    )
                )
            )
        );
        vm.warp(block.timestamp + 90 seconds);
        assertFalse(
            sut.mockValidateSignature(
                sut.DELEGATE_PURCHASE_TYPE_HASH(),
                primaryUser,
                relayer,
                10,
                validAfter,
                validAfter + 1 days,
                keccak256("testNonce2"),
                v,
                r,
                s
            ),
            "Signature should be invalid"
        );
    }

    function testValidateParticipant() public view {
        uint256 amount = 50000000000000000000000;

        assertTrue(
            sut.mockValidateParticipant(primaryUser, amount, proof),
            "Participant should be valid"
        );
    }

    function testInvalidParticipant() public view {
        assertFalse(
            sut.mockValidateParticipant(invalidUser, 1, proof),
            "Participant should be valid"
        );
    }

    function testFinalizeFunding() public {
        vm.warp(block.timestamp + 30 days + 1 seconds);
        sut.finalizeFundingRound();

        assertEq(sut.fundingAmount(), 0, "Funding amount should be zero");
    }

    function testShouldRevertFinalizeFunding() public {
        vm.warp(block.timestamp + 20 days);

        vm.expectRevert(AIAgentShare.FundingRoundNotExpired.selector);
        sut.finalizeFundingRound();
    }

    function testPurchase() public {
        uint256 amount = 50_000 * 10 ** 18;
        uint256 accountBalance = 100_000 ether;

        uint256 etherAmount = (amount * sut.PRICE_PER_TOKEN()) / 10 ** 18;

        uint256 contractBalance = address(sut).balance;

        vm.deal(primaryUser, accountBalance);

        vm.startPrank(primaryUser);

        vm.expectEmit(true, true, true, true);
        emit Purchase(primaryUser);
        sut.purchase{value: 5000 ether}(0, amount, proof);

        vm.stopPrank();

        assertTrue(sut.hasClaimedTokens(0), "User should have claimed tokens");

        assertEq(
            sut.balanceOf(primaryUser),
            amount,
            "Balance should be 50k tokens"
        );

        assertEq(
            sut.fundingAmount(),
            fundingAmount - amount,
            "Funding amount should be reduced by the purchase amount"
        );

        assertEq(
            primaryUser.balance,
            accountBalance - etherAmount,
            "Account balance should be reduced by the purchase amount"
        );

        assertEq(
            address(sut).balance,
            contractBalance + etherAmount,
            "Contract balance should be increased by the purchase amount"
        );
    }

    function testPurchaseShouldRevert() public {
        uint256 amount = 50_00 * 10 ** 18; // wrong amount => hash is not valid
        uint256 accountBalance = 100_000 ether;

        vm.deal(primaryUser, accountBalance);

        vm.startPrank(primaryUser);
        vm.expectRevert(AIAgentShare.UserNotWhitelisted.selector);
        sut.purchase{value: 5000 ether}(0, amount, proof);
        vm.stopPrank();
    }

    function testDelegatePurchase() public {
        vm.deal(relayer, 10_000 ether);
        uint256 validAfter = block.timestamp;
        uint256 expiration = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            primaryUserKey,
            sut.hashedSignatureData(
                keccak256(
                    abi.encode(
                        sut.DELEGATE_PURCHASE_TYPE_HASH(),
                        primaryUser,
                        relayer,
                        50_000 * 10 ** 18,
                        validAfter,
                        expiration,
                        keccak256("testNonc2e")
                    )
                )
            )
        );

        vm.warp(block.timestamp + 90 seconds);

        vm.startPrank(relayer);

        vm.expectEmit(true, true, true, true);
        emit DelegatedPurchase(primaryUser, relayer);

        sut.delegatePurchase{value: 5000 ether}(
            0,
            primaryUser,
            relayer,
            50_000 * 10 ** 18,
            validAfter,
            expiration,
            keccak256("testNonc2e"),
            proof,
            v,
            r,
            s
        );

        assertEq(
            sut.balanceOf(primaryUser),
            50_000 * 10 ** 18 - sut.RELAYER_REWARD(),
            "Balance should be equal to the purchase amount minus the relayer reward"
        );

        assertEq(
            sut.balanceOf(relayer),
            sut.RELAYER_REWARD(),
            "Relayer reward should be minted to the relayer"
        );
        vm.stopPrank();
    }

    function testDelegatePurchaseShouldRevert() public {
        vm.deal(relayer, 10_000 ether);
        uint256 validAfter = block.timestamp;
        uint256 expiration = block.timestamp + 1 days;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            primaryUserKey,
            sut.hashedSignatureData(
                keccak256(
                    abi.encode(
                        sut.DELEGATE_PURCHASE_TYPE_HASH(),
                        primaryUser,
                        relayer,
                        50_000 * 10 ** 18,
                        validAfter,
                        expiration,
                        keccak256("testNonc2e")
                    )
                )
            )
        );

        vm.warp(block.timestamp + 90 seconds);

        vm.startPrank(relayer);

        vm.expectRevert(AIAgentShare.InsufficientFunds.selector);

        sut.delegatePurchase{value: 5001 ether}(
            0,
            primaryUser,
            relayer,
            50_000 * 10 ** 18,
            validAfter,
            expiration,
            keccak256("testNonc2e"),
            proof,
            v,
            r,
            s
        );
        vm.stopPrank();
    }
}
