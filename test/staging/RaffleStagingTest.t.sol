// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";

contract RaffleStagingTest is Test {
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    Raffle public raffle;
    address public vrfCoordinatorV2_5;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        address raffleAddress = vm.envOr("SEPOLIA_RAFFLE_ADDRESS", address(0));
        vrfCoordinatorV2_5 = vm.envOr("SEPOLIA_VRF_COORDINATOR_ADDRESS", address(0));

        if (raffleAddress == address(0) || vrfCoordinatorV2_5 == address(0)) {
            vm.skip(true);
        }

        raffle = Raffle(payable(raffleAddress));
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffle.getEntranceFee()}();
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public raffleEntered {
        // This test requires a local mock coordinator.
        // A live Sepolia VRF request cannot be fulfilled synchronously by a fork test.
        vm.skip(true);
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered {
        // This test requires a live VRF request and its asynchronous callback.
        // Verify the resulting winner and payout through on-chain state after fulfillment.
        vm.skip(true);
    }
}
