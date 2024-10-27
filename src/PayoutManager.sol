// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VeritDAO} from "./VeritDAO.sol";
import {VeritPool} from "./VeritPool.sol";
import {VeritFactory} from "./VeritFactory.sol";

contract PayoutManager {
    error Not_Allowed();
    error Already_Redemed();

    address public poolAddr;
    address public factoryAddr;

    mapping(address => bool) redeemed;

    constructor(address _poolAddr, address _factoryAddr) {
        poolAddr = _poolAddr;
        factoryAddr = _factoryAddr;
    }

    function executePayout(
        address to,
        uint256 impactLoss,
        uint256 severityScore,
        uint256 posVotes,
        address[] memory voters,
        uint256 totalVotes,
        address instanceAddr
    ) public {
        VeritFactory factory = VeritFactory(factoryAddr);
        if (!factory.isInstance(instanceAddr)) revert Not_Allowed();
        if (redeemed[instanceAddr]) revert Already_Redemed();

        redeemed[instanceAddr] = true;

        uint256 severityFactor = severityScore / posVotes;
        if (severityScore % posVotes > posVotes / 2) severityFactor++;

        uint256 payoutAmount = (impactLoss * severityFactor * 1e18) / 5;
        uint256 votersCut = payoutAmount / 20;
        uint256 totalVotersCut = votersCut / totalVotes;

        VeritPool pool = VeritPool(payable(poolAddr));
        pool.transferPayout(to, payoutAmount, voters, totalVotersCut);
    }
}
