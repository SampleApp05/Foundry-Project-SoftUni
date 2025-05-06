// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MockAIAgentShare} from "./MockAIAgenShareToken.sol";

contract AIAgentShareTests is Test {
    uint256 primaryUserKey;
    address primaryUser;
    address invalidUser;
    address relayer;

    uint256 fundingAmount = 5_000_000 * 10 ** 18;
    bytes32 whitelistHash =
        0x2eacf52fc1f9971fdfc90b7ec53c0288092cdfb40dbda0d1aba745bab4602b86;
    uint256 expirationDate = block.timestamp + 30 days;

    MockAIAgentShare sut;

    function setUp() public {
        primaryUserKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        primaryUser = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        invalidUser = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        relayer = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        sut = new MockAIAgentShare(
            primaryUser,
            fundingAmount,
            relayer,
            whitelistHash,
            expirationDate
        );
    }

    function testDeployment() public view {
        assertEq(sut.owner(), primaryUser);
        assertEq(sut.fundingAmount(), fundingAmount);
        assertEq(sut.relayer(), relayer);
        assertEq(sut.whitelisteParticipantsHash(), whitelistHash);
        assertEq(sut.expirationDate(), expirationDate);
    }
}
