// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IFunctionGuzzler} from "./FunctionGuzzler.sol";

/**
 * @dev A contract that demonstrates inefficient function implementations
 */

struct User {
    uint256 balance;
    bool isRegistered;
}

contract FunctionGuzzlerOP is IFunctionGuzzler {
    error UserRegistered();
    error ValueExists();
    error UserNotRegistered();
    error InsufficientBalance();

    event ValueAdded(address user, uint256 value);
    event Transfer(address from, address to, uint256 amount);

    uint256 public valueIndex;
    uint256 public totalAmount;
    mapping(uint256 index => uint256 value) public valuesByIndex;
    mapping(address userAddress => User user) public usersMap;

    function registerUser() external {
        if (usersMap[msg.sender].isRegistered) {
            revert UserRegistered();
        }

        usersMap[msg.sender] = User(0, true);
    }

    function isRegistered(address target) external view returns (bool) {
        return usersMap[target].isRegistered;
    }

    function sumValues() external view returns (uint256) {
        return totalAmount;
    }

    function addValue(uint256 newValue) external {
        if (usersMap[msg.sender].isRegistered == false) {
            revert UserNotRegistered();
        }

        if (valuesByIndex[valueIndex] == newValue) {
            revert ValueExists();
        }
        valuesByIndex[valueIndex] = newValue;
        valueIndex++;
        totalAmount += newValue;
    }

    function deposit(uint256 amount) external {
        User storage user = usersMap[msg.sender];

        if (user.isRegistered == false) {
            revert UserNotRegistered();
        }

        user.balance += amount;
        totalAmount += amount;
    }

    function getBalance(address target) external view returns (uint256) {
        User memory user = usersMap[target];
        if (user.isRegistered == false) {
            revert UserNotRegistered();
        }

        return user.balance;
    }

    function findUser(address user) external view returns (bool) {
        return usersMap[user].isRegistered;
    }

    function transfer(address to, uint256 amount) external {
        User storage sender = usersMap[msg.sender];
        User storage recipient = usersMap[to];

        if (sender.isRegistered == false) {
            revert UserNotRegistered();
        }

        if (recipient.isRegistered == false) {
            revert UserNotRegistered();
        }

        if (sender.balance < amount) {
            revert InsufficientBalance();
        }

        sender.balance -= amount;
        recipient.balance += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function getAverageValue() external view returns (uint256) {
        if (valueIndex == 0) return 0;
        return totalAmount / valueIndex;
    }
}
