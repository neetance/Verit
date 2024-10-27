// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VeritDAO} from "../src/VeritDAO.sol";
import {VeritPool} from "../src/VeritPool.sol";
import {VeritFactory} from "../src/VeritFactory.sol";
import {PayoutManager} from "../src/PayoutManager.sol";
import {VeritInstance} from "../src/VeritInstance.sol";

contract DeployVerit is Script {
    function run() external returns (VeritPool, VeritFactory, PayoutManager) {
        vm.startBroadcast();
        VeritFactory factory = new VeritFactory();
        VeritPool pool = new VeritPool(address(factory));
        PayoutManager payoutManager = new PayoutManager(
            address(pool),
            address(factory)
        );
        vm.stopBroadcast();

        factory.setPool(address(pool));
        factory.setPayoutManager(address(payoutManager));
        pool.setPayoutManager(address(payoutManager));

        return (pool, factory, payoutManager);
    }
}
