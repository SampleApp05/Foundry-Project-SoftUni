// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {VotingToken} from "./VotingToken.sol";

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
}

contract VotingLogicV1 is Initializable, OwnableUpgradeable {
    event ProposalCreated(uint256 proposalId);

    error ProposalDoesNotExist();
    error ExpiredProposal();
    error NoVotingPower();

    uint256 public currentProposalId = 0;
    mapping(uint256 => Proposal) public proposals;
    VotingToken public votingToken;

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner, address token) external initializer {
        __Ownable_init(owner);
        votingToken = VotingToken(token);
    }

    function getUserVotingPower(address user) external view returns (uint256) {
        return votingToken.getVotes(user);
    }

    function getProposalVotes(
        uint256 proposalID
    ) external view returns (uint256 forVotes, uint256 againstVotes) {
        Proposal memory proposal = proposals[proposalID];
        require(proposal.proposer != address(0), ProposalDoesNotExist());
        return (proposal.forVotes, proposal.againstVotes);
    }

    function createProposal(
        string memory description
    ) external returns (uint256 proposalId) {
        uint256 currentId = currentProposalId;
        currentProposalId++;

        Proposal memory newProposal = Proposal({
            id: currentId,
            proposer: msg.sender,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });

        proposals[currentId] = newProposal;
        emit ProposalCreated(currentProposalId);

        return currentId;
    }

    function vote(uint256 proposalID, bool support) external {
        uint256 votingPower = votingToken.getVotes(msg.sender);
        require(votingPower > 0, NoVotingPower());

        Proposal storage proposal = proposals[proposalID];
        require(proposal.proposer != address(0), ProposalDoesNotExist());
        require(proposal.executed == false, ExpiredProposal());

        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
    }

    function executeProposal(uint256 proposalID) public virtual returns (bool) {
        Proposal storage proposal = proposals[proposalID];

        require(proposal.proposer != address(0), ProposalDoesNotExist());
        require(proposal.executed == false, ExpiredProposal());

        proposal.executed = true;
        return proposal.forVotes > proposal.againstVotes; // Execute the proposal logic here
    }
}
