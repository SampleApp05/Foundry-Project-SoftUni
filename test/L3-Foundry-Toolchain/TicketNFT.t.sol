// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {BaseFoundryTest} from "../BaseFoundryTest.sol";
import {TicketNFT} from "src/L3-Foundry-Toolchain/TicketNFT.sol";
import {TestTokenReceiverContract} from "../TestTokenReceiverContract.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TicketNFTTest is BaseFoundryTest, TestTokenReceiverContract {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    string constant NAME = "TicketNFT";
    string constant SYMBOL = "TICKET";
    TicketNFT public sut;

    constructor() BaseFoundryTest() {}

    function setUp() public {
        sut = new TicketNFT(NAME, SYMBOL);
    }

    function test_constructor() public view {
        assertEq(sut.name(), NAME);
        assertEq(sut.symbol(), SYMBOL);
        assertEq(sut.owner(), self);
    }

    function test_minting() public {
        uint256 tokenId = sut.safeMint(validUser);

        assertEq(sut.ownerOf(tokenId), validUser);
        assertEq(sut.balanceOf(validUser), 1);
    }

    function test_mintTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(addressZero, validUser, 0);
        sut.safeMint(validUser);
    }

    function test_transfer() public {
        uint256 tokenId = sut.safeMint(self);
        sut.safeTransferFrom(self, validUser, tokenId);

        assertEq(sut.ownerOf(tokenId), validUser);
        assertEq(sut.balanceOf(self), 0);
        assertEq(sut.balanceOf(validUser), 1);
    }

    function test_transferEvent() public {
        uint256 tokenId = sut.safeMint(self);
        vm.expectEmit(true, true, true, true);
        emit Transfer(self, validUser, tokenId);
        sut.safeTransferFrom(self, validUser, tokenId);
    }

    function test_totalSupply() public {
        uint256 tokenId1 = sut.safeMint(self);
        uint256 tokenId2 = sut.safeMint(self);
        uint256 tokenId3 = sut.safeMint(validUser);

        assertEq(sut.totalSupply(), 3);

        assertEq(sut.tokenByIndex(0), tokenId1);
        assertEq(sut.tokenByIndex(1), tokenId2);
        assertEq(sut.tokenByIndex(2), tokenId3);

        assertEq(sut.tokenOfOwnerByIndex(self, 0), tokenId1);
        assertEq(sut.tokenOfOwnerByIndex(self, 1), tokenId2);
        assertEq(sut.tokenOfOwnerByIndex(validUser, 0), tokenId3);
    }

    function test_RevertOnInvalidIndex() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721Enumerable.ERC721OutOfBoundsIndex.selector,
                addressZero,
                1000
            )
        );

        sut.tokenByIndex(1000);
    }

    function test_revertInvalidOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721Enumerable.ERC721OutOfBoundsIndex.selector,
                self,
                0
            )
        );

        sut.tokenOfOwnerByIndex(self, 0);
    }
}
