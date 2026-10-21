// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-evm/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscriptions is Script {
    function createSunscriptionusingconfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getconfig();
        return createSubscription(config.vrfCoordinator, config.account);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getconfig();
        return createSubscription(vrfCoordinator, config.account);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        vm.startBroadcast(account);
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Created subscription with ID:", subscriptionId);
        console.log("VRF Coordinator:", vrfCoordinator);

        return (subscriptionId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSunscriptionusingconfig();
    }
}

contract FundSubscription is CodeConstants, Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionusingconfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getconfig();

        uint256 subscriptionId = config.subscriptionId;
        address vrfCoordinator = config.vrfCoordinator;

        if (subscriptionId == 0) {
            CreateSubscriptions createSubscriptions = new CreateSubscriptions();
            (subscriptionId, vrfCoordinator) = createSubscriptions.createSubscription(vrfCoordinator, config.account);
        }

        fundSubscription(vrfCoordinator, subscriptionId, config.link, config.account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getconfig();

        _fundSubscription(vrfCoordinator, subscriptionId, linkToken, config.account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account)
        public
    {
        _fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function _fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account)
        internal
    {
        if (block.chainid == Local_Chain_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }

        console.log("Funded subscription:", subscriptionId);
        console.log("VRF Coordinator:", vrfCoordinator);
    }

    function run() external {
        fundSubscriptionusingconfig();
    }
}

contract AddConsumer is Script {
    function AddConsumerusingconfig(address raffleAddress) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getconfig();

        addConsumer(raffleAddress, config.vrfCoordinator, config.subscriptionId, config.account);
    }

    function addConsumer(address raffleAddress, address vrfCoordinator, uint256 subscriptionId) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getconfig();

        addConsumer(raffleAddress, vrfCoordinator, subscriptionId, config.account);
    }

    function addConsumer(address raffleAddress, address vrfCoordinator, uint256 subscriptionId, address account)
        public
    {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, raffleAddress);
        vm.stopBroadcast();

        console.log("Added raffle consumer:", raffleAddress);
        console.log("Subscription ID:", subscriptionId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        AddConsumerusingconfig(mostRecentlyDeployed);
    }
}
