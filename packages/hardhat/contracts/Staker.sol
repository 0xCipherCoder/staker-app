// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract private exampleExternalContract;

	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;

	uint256 public deadline = block.timestamp + 72 hours;
	bool private openForWithdraw = false;

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	event Stake(address, uint256);

	function stake() public payable {
		balances[msg.sender] += msg.value;
		console.log("%s Funds received from %s", msg.value, msg.sender);
		emit Stake(msg.sender, msg.value);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

	function execute() public payable {
		require(block.timestamp > deadline, "Deadline not yet met");
		if (address(this).balance > threshold) {
			exampleExternalContract.complete{ value: address(this).balance }();
		} else {
			openForWithdraw = true;
		}
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

	function withdraw() public payable {
		require(openForWithdraw, "Withdrawal not allowed yet");
		uint256 balance = balances[msg.sender];
		balances[msg.sender] -= balance;
		(bool sent, bytes memory data) = msg.sender.call{ value: balance }("");
		require(sent, "Failed to send Ether");
	}

	modifier notCompleted() {
		require(exampleExternalContract.completed(), "Contract not completed");
		_;
	}

	// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		}
		return deadline - block.timestamp;
	}

	// Add the `receive()` special function that receives eth and calls stake()

	receive() external payable {}
	fallback() external payable {}
}
