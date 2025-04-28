// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract ERC2612Auth is ERC20, EIP712 {
    error InvalidSignature();
    error InactiveSignature();
    error ExpiredSignature();
    error InvalidAddress();
    error InvalidAmount();
    error NonceAlreadyUsed();

    event AuthGranted(
        address indexed owner,
        address indexed spender,
        uint256 value,
        uint256 validAfter,
        uint256 expiration,
        bytes32 nonce
    );

    event AuthCancelled(
        address indexed origin,
        bytes32 nonce,
        uint256 timestamp
    );

    bytes32 constant ALLOWENCE_TYPEHASH =
        keccak256(
            "AllowenceGranted(address owner,address spender,uint256 amount,uint256 validAfter,uint256 expiration,bytes32 nonce)"
        );

    bytes32 constant CANCEL_AUTHORIZATION_TYPEHASH =
        keccak256("AuthCancelled(address origin,bytes32 nonce)");

    mapping(address => mapping(bytes32 => bool)) public userNonces;

    constructor(string memory name) EIP712(name, "1") {}

    function _updateNonces(address owner, bytes32 nonce) private {
        require(userNonces[owner][nonce] == false, NonceAlreadyUsed());
        userNonces[owner][nonce] = true;
    }

    function _validateSignature(
        bytes32 typeHash,
        address owner,
        address spender,
        uint256 amount,
        uint256 validAfter,
        uint256 expiration,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual {
        require(owner != address(0), InvalidAddress());
        require(spender != address(0), InvalidAddress());
        require(amount > 0, InvalidAmount());
        require(block.timestamp > validAfter, InactiveSignature());
        require(block.timestamp < expiration, ExpiredSignature());

        _updateNonces(owner, nonce);

        bytes32 structHash = keccak256(
            abi.encode(
                typeHash,
                owner,
                spender,
                amount,
                validAfter,
                expiration,
                nonce
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);

        require(signer == owner, InvalidSignature());
    }

    function grantAllowenceAuth(
        address owner,
        address spender,
        uint256 amount,
        uint256 validAfter,
        uint256 expiration,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _validateSignature(
            ALLOWENCE_TYPEHASH,
            owner,
            spender,
            amount,
            validAfter,
            expiration,
            nonce,
            v,
            r,
            s
        );

        _approve(owner, spender, amount);

        emit AuthGranted(owner, spender, amount, validAfter, expiration, nonce);
    }

    // @dev This function is used to cancel a previously signed authorization by 'using' the nonce.
    function cancelAuth(
        address origin,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(origin != address(0), InvalidAddress());

        _updateNonces(origin, nonce);

        bytes32 structHash = keccak256(
            abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, origin, nonce)
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);

        require(signer == origin, InvalidSignature());
        emit AuthCancelled(origin, nonce, block.timestamp);
    }
}
