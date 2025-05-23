// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {AIAgentShare} from "src/L9-Excercise/AIAgentShareToken.sol";

contract MockAIAgentShare is AIAgentShare {
    constructor(
        address initialOwner,
        uint256 _fundingAmount,
        address _relayer,
        bytes32 _whitelistHash,
        uint256 _expirationDate
    )
        AIAgentShare(
            initialOwner,
            _fundingAmount,
            _relayer,
            _whitelistHash,
            _expirationDate
        )
    {}

    function hashedSignatureData(bytes32 data) public view returns (bytes32) {
        return _hashTypedDataV4(data);
    }

    function mockValidateSignature(
        bytes32 typeHash,
        address authorizer,
        address target,
        uint256 amount,
        uint256 validAfter,
        uint256 expiration,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (bool) {
        return
            _validateSignature(
                typeHash,
                authorizer,
                target,
                amount,
                validAfter,
                expiration,
                nonce,
                v,
                r,
                s
            );
    }

    function mockValidateParticipant(
        address target,
        uint256 amount,
        bytes32[] memory proof
    ) public view returns (bool) {
        return _validateParticipant(target, amount, proof);
    }

    function mockCreateClaimBitMaskData(
        uint256 userID
    ) public pure returns (uint256, uint256) {
        return _createClaimBitMaskData(userID);
    }

    function mockUpdateClaimStatus(uint256 userID) public {
        _updateClaimStatus(userID);
    }
}
