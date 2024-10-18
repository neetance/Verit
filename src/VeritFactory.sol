// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VeritInstance} from "./VeritInstance.sol";

contract VeritFactory {
    error Value_Not_Equal_To_Payment();
    error Error_Sending_Funds();
    error Invalid_Freelancer_Address();
    error Invalid_Payment_Amount();

    event NewInstance(
        address indexed employer,
        address indexed freelancer,
        uint256 pay,
        address instanceAddress
    );

    function createNewInstance(
        address freelancer,
        uint256 payment
    ) external payable {
        if (msg.value != payment) revert Value_Not_Equal_To_Payment();
        if (freelancer == address(0)) revert Invalid_Freelancer_Address();
        if (payment <= 0) revert Invalid_Payment_Amount();

        VeritInstance newInstance = new VeritInstance(
            msg.sender,
            freelancer,
            payment
        );

        (bool success, ) = payable(address(newInstance)).call{value: payment}(
            ""
        );
        if (!success) revert Error_Sending_Funds();

        emit NewInstance(msg.sender, freelancer, payment, address(newInstance));
    }
}
