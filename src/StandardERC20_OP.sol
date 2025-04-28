// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @dev A standard but gas-inefficient ERC20 implementation
 */

contract StandardERC20_OP {
    error InvalidAmount();
    error InsufficientBalance();
    error TransferToZeroAddress();
    error ApproveToZeroAddress();
    error InsufficientAllowance();

    uint256 public totalSupply;
    bytes32 public name;
    bytes32 public symbol;
    uint8 public immutable decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = bytes32(bytes(_name));
        symbol = bytes32(bytes(_symbol));
        decimals = _decimals;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        mapping(address => uint256) storage userBalances = balanceOf;
        if (userBalances[msg.sender] < value) {
            revert InsufficientBalance();
        }

        require(value > 0, InvalidAmount());
        require(to != address(0), TransferToZeroAddress());

        unchecked {
            userBalances[msg.sender] -= value;
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), ApproveToZeroAddress());

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        mapping(address => uint256) storage userBalances = balanceOf;
        if (userBalances[from] < value) {
            revert InsufficientBalance();
        }

        require(value > 0, InvalidAmount());
        require(from != address(0), TransferToZeroAddress());

        unchecked {
            userBalances[from] -= value;
            userBalances[to] += value;
            allowance[from][msg.sender] -= value;
        }

        emit Transfer(from, to, value);
        return true;
    }
}
