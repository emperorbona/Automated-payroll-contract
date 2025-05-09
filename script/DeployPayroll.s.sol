// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PayRoll} from "../src/Payroll.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployPayRoll is Script {

    function run() external returns (PayRoll, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();

        (uint256 minimumAmount, 
        uint256 interval,
        address vrfCoordinator, 
        // bytes32 gasLane,
        uint64 subscriptionId, 
        // uint32 callbackGasLimit,
        address link
        ) = helperConfig.activeNetworkConfig();

         if(subscriptionId == 0){
            // We are going to create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);

            // Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link
            );

        }

        PayRoll payRoll;
        vm.startBroadcast();
        payRoll = new PayRoll(
            minimumAmount,
            interval
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
          address(payRoll),
          vrfCoordinator,
          subscriptionId  
        );
        return (payRoll,helperConfig);
    }
}
