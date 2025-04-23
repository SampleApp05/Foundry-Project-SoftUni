// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";

contract BaseFoundryTest is Test {
    uint256 currentUserId = 0x6;

    address public constant addressZero = address(0x0);
    address public immutable self;
    address public immutable owner;
    address public immutable validUser;
    address public immutable invalidUser;
    mapping(uint256 => address) public customUsers;

    constructor() {
        self = address(this);
        vm.deal(self, 100 ether);

        (owner, ) = createUser(100);
        (validUser, ) = createUser(100);
        (invalidUser, ) = createUser(0);
    }

    function createUser(uint256 amount) public returns (address, uint256) {
        currentUserId++;
        address user = vm.addr(currentUserId);

        if (amount > 0) {
            vm.deal(user, amount * 1 ether);
        }
        customUsers[currentUserId] = user;

        return (user, currentUserId);
    }

    function blockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function mine() public {
        vm.roll(block.number + 1);
        vm.warp(blockTime() + 1 hours);
    }

    function mineMultiple(uint8 blocks) public {
        for (uint8 i = 0; i < blocks; i++) {
            mine();
        }
    }

    receive() external payable {}
}
