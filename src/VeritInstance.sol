// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VeritInstance {
    address private immutable holder;
    uint256 private immutable premium;
    uint256 private immutable deadline;

    constructor(address _holder, uint256 _premium, uint256 _deadline) {
        holder = _holder;
        premium = _premium;
        deadline = _deadline;
    }
}
