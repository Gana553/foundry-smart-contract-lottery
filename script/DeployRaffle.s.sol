// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptions, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        return deploycontract();
    }

    function deploycontract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getconfig();

        if (networkConfig.subscriptionId == 0) {
            CreateSubscriptions createSubscriptions = new CreateSubscriptions();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) =
                createSubscriptions.createSubscription(networkConfig.vrfCoordinator, networkConfig.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.link, networkConfig.account
            );

            helperConfig.setConfig(block.chainid, networkConfig);
        } else if (block.chainid == 31337) {
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.link, networkConfig.account
            );
        }

        vm.startBroadcast(networkConfig.account);
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addconsumer = new AddConsumer();
        addconsumer.addConsumer(
            address(raffle), networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.account
        );

        return (raffle, helperConfig);
    }
}
