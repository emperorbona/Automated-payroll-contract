// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PayRoll} from "../src/Payroll.sol";
// import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script{

    struct NetworkConfig{
        uint256 minimumAmount;
        uint256 interval;
        address vrfCoordinator; 
        uint64 subscriptionId; 
        address link;
    }
    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaNetworkConfig();
        }
        else if(block.chainid == 1){
            activeNetworkConfig = getMainnetNetworkConfig();
        }
        else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }
    function getSepoliaNetworkConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepoliaNetworkConfig = NetworkConfig({
            minimumAmount: 10 ether,
            interval: 28 days,
            vrfCoordinator : 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            // gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            // callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
        return sepoliaNetworkConfig;
    }

    function getMainnetNetworkConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory mainnetConfig = NetworkConfig({
            minimumAmount : 10 ether,
            interval : 28 days,
            vrfCoordinator : 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            // gasLane: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b,
            subscriptionId: 0,
            // callbackGasLimit: 500000,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        });
        return mainnetConfig;
    }

     function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.vrfCoordinator !=address(0)){
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            minimumAmount : 10 ether,
            interval : 28 days,
            vrfCoordinator: address(vrfCoordinatorV2Mock),
            // gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            // callbackGasLimit: 500000,
            link: address(link)
        });
        return anvilConfig;

    }
}