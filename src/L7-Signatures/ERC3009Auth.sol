// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC2612Auth} from "./ERC2612Auth.sol";

contract ERC3009Auth is ERC2612Auth {
    error UnAuthorizedReceiver();

    event AuthApplied(
        address indexed origin,
        address indexed target,
        bytes32 nonce
    );

    event AuthorizationCanceled(address indexed origin, bytes32 nonce);

    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address origin,address target,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "ReceiveWithAuthorization(address origin,address target,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );

    constructor() ERC20("ERC3009", "PP") ERC2612Auth("ERC3009Auth") {
        _mint(msg.sender, 100_000 ether);
    }

    function transferWithAuthorization(
        address origin,
        address target,
        uint256 amount,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _validateSignature(
            TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
            origin,
            target,
            amount,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );

        _transfer(origin, target, amount);
        emit AuthApplied(origin, target, nonce);
    }

    function receiveWithAuthorization(
        address origin,
        address target,
        uint256 amount,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(target == msg.sender, UnAuthorizedReceiver());

        _validateSignature(
            RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
            origin,
            target,
            amount,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );

        _transfer(origin, target, amount);
        emit AuthApplied(origin, target, nonce);
    }
}
