// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract VeritDAO is Ownable {
    error Must_Be_DAO_Member();
    error Can_Only_Vote_Once();
    error Deadline_Reached();
    error Voting_Ongoing();

    uint256 startTime;
    uint256 public deadline;
    uint256 posVotes;
    uint256 negVotes;

    address public claimer;
    address pool;
    address private admin;

    mapping(address => bool) hasVoted;

    enum State {
        ONGOING,
        APPROVED,
        REJECTED
    }

    State state;

    constructor(address _claimer, address poolAddr) Ownable(admin) {
        claimer = _claimer;
        startTime = block.timestamp;
        deadline = block.timestamp + 7 days;
        state = State.ONGOING;
        pool = poolAddr;
        posVotes = 0;
        negVotes = 0;
    }

    modifier onlyDAOMember(address voter) {
        if (!(IERC20(pool).balanceOf(voter) > 0)) revert Must_Be_DAO_Member();
        _;
    }

    modifier ongoing() {
        if (block.timestamp > deadline) revert Deadline_Reached();
        _;
    }

    function voteFor() public onlyDAOMember(msg.sender) ongoing {
        if (hasVoted[msg.sender]) revert Can_Only_Vote_Once();

        hasVoted[msg.sender] = true;
        uint256 balance = IERC20(pool).balanceOf(msg.sender);
        posVotes += balance;
    }

    function voteAgainst() public onlyDAOMember(msg.sender) ongoing {
        if (hasVoted[msg.sender]) revert Can_Only_Vote_Once();

        hasVoted[msg.sender] = true;
        uint256 balance = IERC20(pool).balanceOf(msg.sender);
        negVotes += balance;
    }

    function execute() external onlyOwner {
        if (block.timestamp < deadline) revert Voting_Ongoing();

        if (negVotes > posVotes) state = State.REJECTED;
        else state = State.APPROVED;
    }
}
