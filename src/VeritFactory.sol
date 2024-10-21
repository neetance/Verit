// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VeritInstance} from "./VeritInstance.sol";
import {VeritPool} from "./VeritPool.sol";

contract VeritFactory {
    error Insufficient_Premium_Amount();

    event NewInstanceCreated(
        address indexed instance,
        address indexed holder,
        uint256 premium
    );

    VeritPool pool;

    uint256 private MAX_PREMIUM = 0.7 ether;
    uint256 private MIN_PREMIUM = 0.3 ether;

    constructor(address poolAddr) {
        pool = VeritPool(poolAddr);
    }

    function newInstance() public payable returns (address) {
        if (msg.value < getPremium()) revert Insufficient_Premium_Amount();

        VeritInstance instance = new VeritInstance(
            msg.sender,
            msg.value,
            block.timestamp + 90 days
        );
        payable(address(pool)).transfer(msg.value);
        emit NewInstanceCreated(address(instance), msg.sender, msg.value);

        return address(instance);
    }

    function getPremium() public view returns (uint256) {
        uint256 base = pool.Base(); // base currently set to 5
        uint256 totalLiquidity = pool.getTotalLiquidity();
        uint256 targetLiquidity = pool.Target();

        uint256 premium = (base * targetLiquidity) / (10 * totalLiquidity); // 0.5 * (target / totalLiquidity)
        if (premium > MAX_PREMIUM) premium = MAX_PREMIUM;
        if (premium < MIN_PREMIUM) premium = MIN_PREMIUM;

        return premium;
    }
}
