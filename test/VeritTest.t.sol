// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VeritDAO} from "../src/VeritDAO.sol";
import {VeritPool} from "../src/VeritPool.sol";
import {VeritFactory} from "../src/VeritFactory.sol";
import {PayoutManager} from "../src/PayoutManager.sol";
import {VeritInstance} from "../src/VeritInstance.sol";
import {DeployVerit} from "../script/DeployVerit.s.sol";
import {console} from "forge-std/console.sol";

contract VeritTest is Test {
    VeritPool pool;
    VeritFactory factory;
    PayoutManager payoutManager;
    DeployVerit deployer;

    function setUp() external {
        deployer = new DeployVerit();
        (pool, factory, payoutManager) = deployer.run();
    }

    function testAddingLiquidity() external {
        for (uint256 i = 1; i <= 5; i++) {
            vm.deal(address(uint160(i)), 2 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: 1 ether}();
        }

        assertEq(pool.getTotalLiquidity(), 5 ether);
        assertEq(pool.balanceOf(address(2)), 1e18);
        //console.log(pool.balanceOf(address(2)));
    }

    function testCreatingInstance() external {
        for (uint256 i = 1; i <= 520; i++) {
            vm.deal(address(uint160(i)), 5 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: 2 ether}();
        }

        uint256 premium = factory.getPremium();
        vm.deal(address(uint160(1000)), premium);
        vm.prank(address(uint160(1000)));
        //console.log(premium);

        factory.newInstance{value: premium}();
        assertEq(pool.getTotalLiquidity(), 1040 ether + premium);
        //console.log(pool.getTotalLiquidity());
    }

    function testClaimingInstance() external {
        for (uint256 i = 1; i <= 520; i++) {
            vm.deal(address(uint160(i)), 5 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: 2 ether}();
        }

        uint256 premium = factory.getPremium();
        address user = address(uint160(1000));
        vm.deal(user, premium);
        vm.prank(user);

        VeritInstance instance = VeritInstance(
            factory.newInstance{value: premium}()
        );

        vm.expectRevert(VeritInstance.NotHolder.selector);
        vm.prank(address(70));
        instance.claim(5);

        vm.prank(user);
        address daoAddr = instance.claim(5);
        VeritDAO dao = VeritDAO(daoAddr);

        address claimer = dao.claimer();
        assertEq(claimer, user);
        assertEq(dao.impactLoss(), 5);
    }
}
