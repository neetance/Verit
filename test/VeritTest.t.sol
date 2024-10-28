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

    function testRemovingLiquidity() external {
        address provider = address(uint160(100));
        vm.deal(provider, 2 ether);
        vm.prank(provider);
        pool.addLiquidity{value: 1 ether}();

        assertEq(provider.balance, 1 ether);
        vm.expectRevert(
            VeritPool.Amount_To_Remove_Greater_Than_Balance.selector
        );
        vm.prank(provider);
        pool.removeLiquidity(2 ether);

        vm.prank(provider);
        pool.removeLiquidity(0.6 ether);

        assertEq(provider.balance, 1.6 ether);
        assertEq(pool.getTotalLiquidity(), 0.4 ether);
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

    function testOnlyDAOMembersCanVote() external {
        for (uint256 i = 1; i <= 5; i++) {
            vm.deal(address(uint160(i)), 2 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: 1 ether}();
        }

        uint256 premium = factory.getPremium();
        address user = address(uint160(1000));
        vm.deal(user, premium);
        vm.prank(user);

        VeritInstance instance = VeritInstance(
            factory.newInstance{value: premium}()
        );

        vm.prank(user);
        address daoAddr = instance.claim(5 ether);
        VeritDAO dao = VeritDAO(daoAddr);

        vm.expectRevert(VeritDAO.Must_Be_DAO_Member.selector);
        vm.prank(address(70));
        dao.voteFor(3);
    }

    function testVotersCantVoteTwice() external {
        for (uint256 i = 1; i <= 5; i++) {
            vm.deal(address(uint160(i)), 2 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: 1 ether}();
        }

        uint256 premium = factory.getPremium();
        address user = address(uint160(1000));
        vm.deal(user, premium);
        vm.prank(user);

        VeritInstance instance = VeritInstance(
            factory.newInstance{value: premium}()
        );

        vm.prank(user);
        address daoAddr = instance.claim(5 ether);
        VeritDAO dao = VeritDAO(daoAddr);

        for (uint256 i = 1; i <= 5; i++) {
            vm.prank(address(uint160(i)));
            dao.voteFor(3);
        }

        vm.expectRevert(VeritDAO.Can_Only_Vote_Once.selector);
        vm.prank(address(uint160(3)));
        dao.voteAgainst();
    }

    function executeEntireProcess(
        uint256 liquidity,
        uint256 claimAmount,
        address user
    ) internal returns (bool, address) {
        for (uint256 i = 48; i <= 62; i++) {
            vm.deal(address(uint160(i)), 5 ether);
            vm.prank(address(uint160(i)));
            pool.addLiquidity{value: liquidity}();
        }

        uint256 premium = factory.getPremium();
        vm.deal(user, premium);
        vm.prank(user);

        VeritInstance instance = VeritInstance(
            factory.newInstance{value: premium}()
        );

        vm.prank(user);
        address daoAddr = instance.claim(claimAmount);
        VeritDAO dao = VeritDAO(daoAddr);

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

        vm.warp(dao.deadline() + 10 minutes);
        vm.prank(user);
        bool result = instance.redeem();
        return (result, address(instance));
    }

    function testProcessForAppropriateClaimAmount() external {
        //claimer provides an appropriate claim amount

        address user = address(uint160(1000));
        (bool result, ) = executeEntireProcess(4 ether, 5 ether, user);
        assert(result);
        assert(address(user).balance < 3 ether);
        assert(address(user).balance > 2.8 ether);
    }

    function testProcessForExcessiveClaimAmount() external {
        //claimer provides a claim amount greater than 10% of the pool balance

        address user = address(uint160(1000));
        (bool result, ) = executeEntireProcess(4 ether, 15 ether, user);
        assert(result);
        assert(address(user).balance < 6 ether);
        assert(address(user).balance > 5.7 ether);
    }

    function testClaimerCantClaimTwice() external {
        address user = address(uint160(1000));
        (bool result, address instance) = executeEntireProcess(
            4 ether,
            5 ether,
            user
        );
        assert(result);

        vm.expectRevert(VeritInstance.AlreadyClaimed.selector);
        vm.prank(user);
        VeritInstance(instance).claim(5);

        vm.expectRevert(VeritInstance.AlreadyClaimed.selector);
        vm.prank(user);
        VeritInstance(instance).redeem();
    }

    function testCannotExecuteDuringVotingPeriod() external {
        address user = address(uint160(1000));
        address provider = address(uint160(1001));
        vm.deal(provider, 5 ether);

        vm.prank(provider);
        pool.addLiquidity{value: 4 ether}();

        uint256 premium = factory.getPremium();
        vm.deal(user, premium);
        vm.startPrank(user);

        VeritInstance instance = VeritInstance(
            factory.newInstance{value: premium}()
        );
        instance.claim(5 ether);
        vm.stopPrank();

        vm.expectRevert(VeritDAO.Voting_Ongoing.selector);
        vm.prank(user);
        instance.redeem();
    }
}
