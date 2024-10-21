// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract VeritPool {
    uint256 private totalLiquidity;
    uint256 private BASE = 5;
    uint256 private TARGET = 1000;

    function Base() public view returns (uint256) {
        return BASE;
    }

    function Target() public view returns (uint256) {
        return TARGET;
    }

    function getTotalLiquidity() public view returns (uint256) {
        return totalLiquidity;
    }
}
