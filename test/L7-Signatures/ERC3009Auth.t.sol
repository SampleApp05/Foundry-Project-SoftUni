// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BaseFoundryTest} from "../BaseFoundryTest.sol";
import {MockERC3009AuthContract} from "./MockERC3009AuthContract.sol";
import {ERC2612Auth} from "src/L7-Signatures/ERC2612Auth.sol";

contract AuthTest is Test {
    MockERC3009AuthContract public sut;

    event AuthApplied(
        address indexed origin,
        address indexed target,
        bytes32 nonce
    );

    event AuthGranted(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event AuthCancelled(
        address indexed origin,
        bytes32 nonce,
        uint256 timestamp
    );

    event AuthorizationCanceled(address indexed origin, bytes32 nonce);

    uint256 ownerKey = 0x123;
    address owner;
    address spender = vm.addr(0x63226);

    function setUp() public {
        ownerKey = 0x666;
        owner = vm.addr(ownerKey);

        sut = new MockERC3009AuthContract();
        sut.transfer(owner, 10_000 ether);
        sut.transfer(spender, 10 ether);
    }

    function testGrantAllowence() public {
        uint256 amount = 10 ether;
        bytes32 nonce = keccak256("nonce");
        uint256 validAfter = block.timestamp;
        uint256 expiration = block.timestamp + 1 days;

        vm.startPrank(owner);

        // Correct struct hash
        bytes32 dataHash = keccak256(
            abi.encode(
                sut.ALLOWANCE_TYPEHASH(),
                owner,
                spender,
                amount,
                validAfter,
                expiration,
                nonce
            )
        );

        bytes32 digest = sut.hashedSignatureData(dataHash);

        // Now sign the digest, not structHash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);

        vm.expectEmit(true, true, true, true);
        emit AuthGranted(owner, spender, amount);

        sut.grantAllowenceAuth(
            owner,
            spender,
            amount,
            validAfter,
            expiration,
            nonce,
            v,
            r,
            s
        );

        vm.stopPrank();

        uint256 allowence = sut.allowance(owner, spender);
        assertEq(allowence, amount, "Allowence not granted correctly");
    }

    function testTransferWithAuth() public {
        uint256 amount = 1 ether;
        bytes32 nonce = keccak256("nonce");
        uint256 validAfter = block.timestamp;
        uint256 expiration = block.timestamp + 1 days;

        vm.startPrank(owner);

        // Correct struct hash
        bytes32 dataHash = keccak256(
            abi.encode(
                sut.TRANSFER_WITH_AUTHORIZATION_TYPEHASH(),
                owner,
                spender,
                amount,
                validAfter,
                expiration,
                nonce
            )
        );

        bytes32 digest = sut.hashedSignatureData(dataHash);

        // Now sign the digest, not structHash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);

        uint256 initialBalance = sut.balanceOf(spender);

        vm.stopPrank();

        vm.startPrank(address(sut));

        vm.expectEmit(true, true, true, true);
        emit AuthApplied(owner, spender, nonce);

        sut.transferWithAuthorization(
            owner,
            spender,
            amount,
            validAfter,
            expiration,
            nonce,
            v,
            r,
            s
        );

        assertEq(
            sut.balanceOf(spender),
            initialBalance + amount,
            "Transfer failed Mismatch"
        );

        vm.stopPrank();
    }

    function testReceiveWithAuth() public {
        uint256 amount = 1 ether;
        bytes32 nonce = keccak256("nonce");
        uint256 validAfter = block.timestamp;
        uint256 expiration = block.timestamp + 1 days;

        vm.startPrank(owner);

        // Correct struct hash
        bytes32 dataHash = keccak256(
            abi.encode(
                sut.RECEIVE_WITH_AUTHORIZATION_TYPEHASH(),
                owner,
                spender,
                amount,
                validAfter,
                expiration,
                nonce
            )
        );

        bytes32 digest = sut.hashedSignatureData(dataHash);

        // Now sign the digest, not structHash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);

        uint256 initialBalance = sut.balanceOf(spender);

        vm.stopPrank();

        vm.startPrank(spender);

        vm.expectEmit(true, true, true, true);
        emit AuthApplied(owner, spender, nonce);

        sut.receiveWithAuthorization(
            owner,
            spender,
            amount,
            validAfter,
            expiration,
            nonce,
            v,
            r,
            s
        );

        assertEq(
            sut.balanceOf(spender),
            initialBalance + amount,
            "Transfer failed Mismatch"
        );

        vm.stopPrank();
    }

    function testCancelAuth() public {
        bytes32 nonce = keccak256("nonce");

        // Correct struct hash
        bytes32 dataHash = keccak256(
            abi.encode(sut.CANCEL_AUTHORIZATION_TYPEHASH(), owner, nonce)
        );

        bytes32 digest = sut.hashedSignatureData(dataHash);

        // Now sign the digest, not structHash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);

        vm.startPrank(owner);

        vm.expectEmit(true, true, true, true);
        emit AuthCancelled(owner, nonce, block.timestamp);

        sut.cancelAuth(owner, nonce, v, r, s);

        vm.expectRevert(ERC2612Auth.NonceAlreadyUsed.selector);
        sut.cancelAuth(owner, nonce, v, r, s);

        vm.stopPrank();
    }
}
