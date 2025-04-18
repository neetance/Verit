// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VeritDAO} from "./VeritDAO.sol";

contract VeritInstance {
    error AlreadyClaimed();
    error DeadlinePassed();
    error NotHolder();

    address private immutable holder;
    address pool;
    address payoutManager;
    uint256 private immutable premium;
    uint256 private immutable deadline;
    bool public claimed;

    VeritDAO dao;

    constructor(
        address _holder,
        uint256 _premium,
        uint256 _deadline,
        address _payoutManager,
        address _pool
    ) {
        holder = _holder;
        premium = _premium;
        deadline = _deadline;
        claimed = false;
        payoutManager = _payoutManager;
        pool = _pool;
    }

    modifier onlyHolder() {
        if (msg.sender != holder) revert NotHolder();
        _;
    }

    function claim(uint256 lossAmount) public onlyHolder returns (address) {
        if (claimed) {
            revert AlreadyClaimed();
        }
        if (block.timestamp >= deadline) {
            revert DeadlinePassed();
        }

        dao = new VeritDAO(holder, pool, payoutManager, lossAmount);
        return address(dao);
    }

    function redeem() public onlyHolder returns (bool) {
        if (claimed) {
            revert AlreadyClaimed();
        }
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }

        claimed = true;
        return dao.execute();
    }
}
