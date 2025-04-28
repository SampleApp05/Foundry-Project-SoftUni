// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";

contract BaseFoundryTest is Test {
    uint256 currentUserId = 10;

    address public constant addressZero = address(0x0);
    address public immutable self;
    address public immutable owner;
    address public immutable validUser;
    address public immutable invalidUser;
    mapping(uint256 => address) public customUsers;

    constructor() {
        self = address(this);
        vm.deal(self, 10_000 ether);

        owner = createUserAddress(0x1, 100);
        validUser = createUserAddress(0x2, 100);
        invalidUser = createUserAddress(0x3, 0);
    }

    function createUserAddress(
        uint256 key,
        uint256 amount
    ) private returns (address) {
        address user = vm.addr(key);

        if (amount > 0) {
            vm.deal(user, amount * 1 ether);
        }
        return user;
    }

    function createUser(uint256 amount) public returns (address, uint256) {
        address user = vm.addr(currentUserId);

        if (amount > 0) {
            vm.deal(user, amount * 1 ether);
        }
        customUsers[currentUserId] = user;
        currentUserId++;

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
        for (uint8 i = 0; i < blocks; ) {
            mine();
            unchecked {
                i++;
            }
        }
    }

    receive() external payable {}
}
