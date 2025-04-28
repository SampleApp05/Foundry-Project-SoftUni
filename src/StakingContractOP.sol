// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev A simple staking contract with inefficient gas implementation
 */
contract StakingContractOP {
    error InvalidAmount();
    error InsufficientBalance();
    error NoAccumulatedRewards();

    IERC20 public immutable stakingToken;
    uint256 public constant REWARD_RATE = 100;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastUpdateBlock;
        uint256 rewardsAccumulated;
    }

    mapping(address => UserInfo) public userInfo;
    address[] public stakers;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    // function calculateReward(
    //     uint256 userStake,
    //     uint256 lastUpdateBlock
    // ) private view returns (uint256) {
    //     return
    //         (userStake * REWARD_RATE * (block.number - lastUpdateBlock)) / 1e18;
    // }

    function stake(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        // Update rewards first
        if (user.stakedAmount > 0) {
            updateReward(msg.sender);
        }

        stakingToken.transferFrom(msg.sender, address(this), amount); // would fail if amount == 0

        user.stakedAmount += amount;

        if (user.lastUpdateBlock == 0) {
            stakers.push(msg.sender);
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedAmount >= amount, InsufficientBalance());

        updateReward(msg.sender);
        unchecked {
            user.stakedAmount -= amount;
        }

        stakingToken.transfer(msg.sender, amount); // would fail if amount == 0

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external {
        updateReward(msg.sender);
        UserInfo storage user = userInfo[msg.sender];

        uint256 reward = user.rewardsAccumulated;
        require(user.rewardsAccumulated > 0, NoAccumulatedRewards());

        user.rewardsAccumulated = 0;
        stakingToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function updateReward(address account) public {
        UserInfo storage user = userInfo[account];

        uint256 newRewards = (user.stakedAmount *
            REWARD_RATE *
            (block.number - user.lastUpdateBlock)) / 1e18;

        if (newRewards > 0) {
            user.rewardsAccumulated += newRewards;
            user.lastUpdateBlock = block.number;
        }
    }

    function updateAllRewards() external {
        address[] memory currentStakers = stakers;

        for (uint256 i = 0; i < currentStakers.length; ) {
            updateReward(currentStakers[i]);
            unchecked {
                i++;
            }
        }
    }

    function pendingReward(address account) external view returns (uint256) {
        UserInfo memory user = userInfo[account];

        uint256 pending = user.rewardsAccumulated;

        if (user.stakedAmount == 0) {
            return pending;
        }

        uint256 newRewards = (user.stakedAmount *
            REWARD_RATE *
            (block.number - user.lastUpdateBlock)) / 1e18;

        unchecked {
            return pending += newRewards;
        }
    }
}
