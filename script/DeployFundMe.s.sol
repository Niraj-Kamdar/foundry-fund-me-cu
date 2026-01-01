// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {Variable} from "forge-std/LibVariable.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract DeployFundMe is Script, Config {
    bool private writeBack;

    function deployFundMe(bool _writeBack) public returns (FundMe) {
        writeBack = _writeBack;
        // Load config with optional write-back
        _loadConfig("./deployments.toml", _writeBack);

        // Get price feed address (deploys mock for local chain)
        address priceFeed = getPriceFeed();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }

    function deployFundMe() public returns (FundMe) {
        // Default: enable write-back for scripts
        return deployFundMe(true);
    }

    function getPriceFeed() internal returns (address) {
        // Check if we should use mocks
        bool useMocks = config.get("use_mocks").toBool();

        if (useMocks) {
            // For mock environments, deploy MockV3Aggregator
            uint8 decimals = uint8(config.get("mock_decimals").toUint256());
            int256 initialPrice = int256(config.get("mock_initial_price").toUint256());

            vm.startBroadcast();
            MockV3Aggregator mock = new MockV3Aggregator(decimals, initialPrice);
            vm.stopBroadcast();

            // Write the deployed mock address back to config if write-back is enabled
            if (writeBack) {
                config.set("price_feed", address(mock));
            }

            return address(mock);
        } else {
            // For other chains, read from config
            return config.get("price_feed").toAddress();
        }
    }

    function run() external returns (FundMe) {
        return deployFundMe();
    }
}
