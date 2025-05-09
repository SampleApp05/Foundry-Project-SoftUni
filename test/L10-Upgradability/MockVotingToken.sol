// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VotingToken} from "src/L10-Upgradability/VotingToken.sol";

contract MockVotingToken is VotingToken {
    constructor() VotingToken() {}
    function hashedSignatureData(bytes32 data) public view returns (bytes32) {
        return _hashTypedDataV4(data);
    }
}
