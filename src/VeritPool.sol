// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract VeritPool is ERC20 {
    error Value_Must_Be_Greater_Than_Zero();
    error Amount_To_Remove_Greater_Than_Balance();

    event LiquidityAdded(address indexed provider, uint256 liquidityAmount);

    uint256 private BASE = 5;
    uint256 private TARGET = 1000;

    constructor(address tokenAddr) ERC20("Verit", "VER") {}

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
}
