// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCrowdFunding is Script {
    function run() public returns (TokenFactory, Crowdfunding) {
        HelperConfig config = new HelperConfig();

        (uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        TokenFactory tokenFactory = new TokenFactory();
        Crowdfunding crowdfunding = new Crowdfunding(address(tokenFactory));
        vm.stopBroadcast();

        return (tokenFactory, crowdfunding);
    }
}
