// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";
import {DecentralizedStablecoin} from "../../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

contract DSCEngineBaseTest is Test {

    DeployDSC deployer;
    DecentralizedStablecoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    function setUp() public virtual {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
    }

}