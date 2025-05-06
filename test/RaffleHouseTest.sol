// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {BaseFoundryTest} from "./BaseFoundryTest.sol";
import {RaffleHouse} from "../src/RaffleHouse.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {TestTokenReceiverContract} from "./TestTokenReceiverContract.sol";
// import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract RaffleHouseTest is BaseFoundryTest, TestTokenReceiverContract {
    RaffleHouse public sut;

    function setUp() public {
        sut = new RaffleHouse();
    }

    function createRaffle() public {
        sut.createRaffle(
            1 ether,
            blockTime(),
            blockTime() + 2 hours,
            "Test Name",
            "TN"
        );
    }

    function buyRaffleTickets() public {
        createRaffle();
        sut.buyTicket{value: 1 ether}(0);
        sut.buyTicket{value: 1 ether}(0);
        sut.buyTicket{value: 1 ether}(0);
        sut.buyTicket{value: 1 ether}(0);

        vm.prank(validUser);
        sut.buyTicket{value: 1 ether}(0);
        sut.buyTicket{value: 1 ether}(0);
        sut.buyTicket{value: 1 ether}(0);
        sut.buyTicket{value: 1 ether}(0);
        vm.prank(self);
    }

    function pickWinner(
        uint256 raffleID
    ) public returns (address winner, uint256 ticketIndex) {
        mineMultiple(3);

        uint256 winningTicketIndex;

        while (winningTicketIndex == 0) {
            sut.chooseWinner(raffleID);
            winningTicketIndex = sut.getRaffle(raffleID).winningTicketIndex;
        }

        return (
            sut.getRaffle(raffleID).ticketsContract.ownerOf(winningTicketIndex),
            winningTicketIndex
        );
    }

    function test_RaffleCreation() public {
        uint256 raffleID = sut.raffleCount();
        createRaffle();
        uint256 raffleCount = sut.raffleCount();

        (uint256 ticketPrice, , , , ) = sut.raffles(0);

        assertNotEq(ticketPrice, 0, "Raffle not created!");
        assertEq(raffleID + 1, raffleCount, "Raffle count mismatch");
    }

    function test_ShouldEmitEventOnRaffleCreation() public {
        vm.expectEmit(true, true, true, true);

        emit RaffleHouse.RaffleCreated(
            0,
            1 ether,
            blockTime(),
            blockTime() + 2 hours,
            "Test Name",
            "TN"
        );

        createRaffle();
    }

    function test_BuyRaffleTicket() public {
        createRaffle();
        uint256 raffleID = sut.raffleCount() - 1;
        TicketNFT ticketContract = sut.getRaffle(0).ticketsContract;

        uint256 initialTokenBalance = ticketContract.balanceOf(self);

        sut.buyTicket{value: 1 ether}(raffleID);

        assertTrue(
            ticketContract.ownerOf(0) == self,
            "Ticket not owned by user"
        );

        assertTrue(
            ticketContract.balanceOf(self) == initialTokenBalance + 1,
            "Ticket balance mismatch"
        );

        assertEq(1, ticketContract.totalSupply(), "Transfer failed Mismatch");
    }

    function test_ShouldEmitEventOnTicketPurchase() public {
        createRaffle();

        vm.expectEmit(true, true, true, true);
        emit RaffleHouse.TicketPurchased(0, self, 0);

        sut.buyTicket{value: 1 ether}(0);
    }

    function test_ChooseWinner() public {
        buyRaffleTickets();
        uint256 raffleID = sut.raffleCount() - 1;

        (, uint256 winningIndex) = pickWinner(raffleID);

        assertTrue(winningIndex > 0, "Invalid winning ticket index");
    }

    function test_ShouldEmitEventOnWinnerSelection() public {
        buyRaffleTickets();
        mineMultiple(3);

        vm.expectEmit(true, false, false, false);
        emit RaffleHouse.WinnerChosen(0, 1);
        sut.chooseWinner(0);
    }

    function test_ClaimPrize() public {
        buyRaffleTickets();
        uint256 raffleID = sut.raffleCount() - 1;
        TicketNFT ticketContract = sut.getRaffle(raffleID).ticketsContract;

        (address winner, ) = pickWinner(raffleID);

        uint256 initialBalance = winner.balance;
        uint256 prizeAmount = sut.getRaffle(raffleID).ticketPrice *
            ticketContract.totalSupply();

        vm.startPrank(winner);

        ticketContract.setApprovalForAll(address(sut), true);
        vm.expectEmit(true, true, true, true);
        emit RaffleHouse.PrizeClaimed(raffleID, winner, prizeAmount);
        sut.claimPrize(raffleID);

        vm.stopPrank();

        assertTrue(
            winner.balance == initialBalance + prizeAmount,
            "Prize not claimed successfully"
        );
    }
}
