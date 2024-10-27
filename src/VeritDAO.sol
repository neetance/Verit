// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {PayoutManager} from "./PayoutManager.sol";

contract VeritDAO is Ownable {
    error Must_Be_DAO_Member();
    error Can_Only_Vote_Once();
    error Deadline_Reached();
    error Voting_Ongoing();
    error Already_Executed();

    event NewVote(address indexed voter, uint256 severity, bool voteFor);

    uint256 startTime;
    uint256 public deadline;
    uint256 public posVotes;
    uint256 public negVotes;
    uint256 public severityScore;
    uint256 public impactLoss;

    address public claimer;
    address pool;
    address instance;
    address payoutManagerAddr;
    address[] public voters;

    mapping(address => bool) hasVoted;

    enum State {
        ONGOING,
        APPROVED,
        REJECTED
    }

    State state;

    constructor(
        address _claimer,
        address poolAddr,
        address _payoutManagerAddr,
        uint256 _impactLoss
    ) Ownable(msg.sender) {
        claimer = _claimer;
        startTime = block.timestamp;
        deadline = block.timestamp + 7 days;
        state = State.ONGOING;
        pool = poolAddr;
        posVotes = 0;
        negVotes = 0;
        severityScore = 0;
        impactLoss = _impactLoss;
        instance = msg.sender;
        payoutManagerAddr = _payoutManagerAddr;
    }

    modifier onlyDAOMember(address voter) {
        if (!(IERC20(pool).balanceOf(voter) > 0)) revert Must_Be_DAO_Member();
        _;
    }

    modifier ongoing() {
        if (block.timestamp > deadline) revert Deadline_Reached();
        _;
    }

    modifier notVoted() {
        if (hasVoted[msg.sender]) revert Can_Only_Vote_Once();
        _;
    }

    function voteFor(
        uint256 severity
    ) public onlyDAOMember(msg.sender) ongoing notVoted {
        hasVoted[msg.sender] = true;
        uint256 balance = IERC20(pool).balanceOf(msg.sender);
        posVotes += balance;
        severityScore += severity;

        voters.push(msg.sender);
        emit NewVote(msg.sender, severity, true);
    }

    function voteAgainst() public onlyDAOMember(msg.sender) ongoing notVoted {
        hasVoted[msg.sender] = true;
        uint256 balance = IERC20(pool).balanceOf(msg.sender);
        negVotes += balance;

        voters.push(msg.sender);
        emit NewVote(msg.sender, 0, false);
    }

    function execute() external onlyOwner returns (bool) {
        if (block.timestamp < deadline) revert Voting_Ongoing();
        if (state != State.ONGOING) revert Already_Executed();

        if (negVotes > posVotes) {
            state = State.REJECTED;
            return false;
        } else {
            state = State.APPROVED;
            PayoutManager payoutManager = PayoutManager(payoutManagerAddr);
            payoutManager.executePayout(
                claimer,
                impactLoss,
                severityScore,
                posVotes,
                instance
            );

            return true;
        }
    }
}
