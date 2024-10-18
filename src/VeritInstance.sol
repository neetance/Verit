// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VeritInstance {
    address private immutable employer;
    address private immutable freelancer;
    uint256 private immutable payment;

    constructor(
        address employerAddr,
        address freelancerAddr,
        uint256 _payment
    ) {
        employer = employerAddr;
        freelancer = freelancerAddr;
        payment = _payment;
    }
}
