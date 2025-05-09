// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VotingLogicV1, Proposal} from "./VotingLogicV1.sol";

contract VotingLogicV2 is VotingLogicV1 {
    error QuoromNotReached();

    function minQuorum() public pure returns (uint256) {
        return 1000 * 10 ** 18; // Example value, adjust as needed
    }

    function executeProposal(
        uint256 proposalID
    ) public override returns (bool) {
        Proposal storage proposal = proposals[proposalID];
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;

        require(minQuorum() < totalVotes, QuoromNotReached());
        return super.executeProposal(proposalID);
    }
}
