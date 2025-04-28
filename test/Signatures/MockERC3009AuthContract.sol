// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ERC3009Auth} from "../../src/Signatures/ERC3009Auth.sol";

contract MockERC3009AuthContract is ERC3009Auth {
    constructor() ERC3009Auth() {}
    function hashedSignatureData(bytes32 data) public view returns (bytes32) {
        return _hashTypedDataV4(data);
    }

    function validateSignature(
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
    ) public {
        _validateSignature(
            typeHash,
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
    }
}
