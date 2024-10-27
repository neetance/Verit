// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract VeritPool is ERC20 {
    error Value_Must_Be_Greater_Than_Zero();
    error Amount_To_Remove_Greater_Than_Balance();
    error Not_Allowed();

    event LiquidityAdded(address indexed provider, uint256 liquidityAmount);
    event LiquidityRemoved(address indexed provider, uint256 liquidityAmount);
    event PayoutTransferred(address indexed to, uint256 amount);

    uint256 private BASE = 5 ether;
    uint256 private TARGET = 1000 ether;
    address payoutManager;
    address factory;

    constructor(address factoryAddr) ERC20("Verit", "VER") {
        factory = factoryAddr;
    }

    function addLiquidity() public payable {
        if (msg.value == 0) revert Value_Must_Be_Greater_Than_Zero();

        uint256 liquidityAdded = msg.value;
        _mint(msg.sender, liquidityAdded);

        emit LiquidityAdded(msg.sender, liquidityAdded);
    }

    function removeLiquidity(uint256 amount) public {
        if (amount > balanceOf(msg.sender))
            revert Amount_To_Remove_Greater_Than_Balance();

        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);

        emit LiquidityRemoved(msg.sender, amount);
    }

    function transferPayout(
        address to,
        uint256 amount,
        address[] memory voters,
        uint256 totalVotersCut
    ) external {
        if (msg.sender != payoutManager) revert Not_Allowed();

        if (amount > ((address(this).balance * 1e18) / 10))
            amount = ((address(this).balance * 1e18) / 10);

        for (uint256 i = 0; i < voters.length; i++) {
            uint256 amountToTransfer = (balanceOf(voters[i]) * totalVotersCut);
            amount -= amountToTransfer;

            payable(voters[i]).transfer((amountToTransfer / 1e18));
        }
        uint256 netAmount = amount / 1e18;

        payable(to).transfer(netAmount);
        emit PayoutTransferred(to, netAmount);
    }

    function setPayoutManager(address _payoutManager) external {
        if (msg.sender != factory) revert Not_Allowed();
        payoutManager = _payoutManager;
    }

    function Base() public view returns (uint256) {
        return BASE;
    }

    function Target() public view returns (uint256) {
        return TARGET;
    }

    function getTotalLiquidity() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
