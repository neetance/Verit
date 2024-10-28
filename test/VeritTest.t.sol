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

    function testVotingInDAOandClaimerGetsPayout() external {
        for (uint256 i = 48; i <= 62; i++) {
            vm.deal(address(uint160(i)), 5 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: 4 ether}();
        }

        uint256 premium = factory.getPremium();
        address user = address(uint160(1000));
        vm.deal(user, premium);
        vm.prank(user);

        VeritInstance instance = VeritInstance(
            factory.newInstance{value: premium}()
        );
        // console.log(address(pool).balance);
        // console.log(address(51).balance);

        vm.prank(user);
        address daoAddr = instance.claim(5 ether);
        VeritDAO dao = VeritDAO(daoAddr);

        vm.expectRevert(VeritDAO.Must_Be_DAO_Member.selector);
        vm.prank(address(70));
        dao.voteFor(3);

        for (uint256 i = 2; i <= 6; i++) {
            vm.prank(address(uint160(46 + i)));
            dao.voteAgainst();
        }

        for (uint256 i = 7; i <= 9; i++) {
            vm.prank(address(uint160(46 + i)));
            dao.voteFor(3);
        }

        for (uint256 i = 10; i <= 12; i++) {
            vm.prank(address(uint160(46 + i)));
            dao.voteFor(2);
        }

        for (uint256 i = 13; i <= 16; i++) {
            vm.prank(address(uint160(46 + i)));
            dao.voteFor(4);
        }

        vm.expectRevert(VeritDAO.Can_Only_Vote_Once.selector);
        vm.prank(address(uint160(48)));
        dao.voteAgainst();

        vm.warp(dao.deadline() + 10 minutes);
        vm.prank(address(instance));
        bool result = dao.execute();

        assert(result);
        console.log(address(user).balance);
    }
}
