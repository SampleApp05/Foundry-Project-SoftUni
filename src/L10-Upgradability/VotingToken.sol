// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract VotingToken is ERC20, ERC20Permit, ERC20Votes {
    uint256 public constant DEPLOYER_REWARD = 1_000_000 * 10 ** 18; // 1 million tokens

    constructor() ERC20("VotingToken", "VT") ERC20Permit("VotingToken") {
        _mint(msg.sender, DEPLOYER_REWARD);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function delegateVotes() public {
        super.delegate(msg.sender);
    }

    function delegateVotesTo(address target) public {
        super.delegate(target);
    }

    function delegateVotesWithSignature(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        super.delegateBySig(delegatee, nonce, expiry, v, r, s);
    }
}
