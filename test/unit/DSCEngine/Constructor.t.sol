// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {DSCEngineBaseTest} from "./BaseTest.t.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";

contract DSCEngineConstructorTest is DSCEngineBaseTest {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    /////////////
    // Sad Path
    /////////////

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /////////////////
    // Happy Path
    /////////////////

    function testDscWorks() public {

        // Given - Insertar token y pricefeed
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);

        // When - Crear contrato
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        // Then - Comprobar estado de variables del contrato

        // Token
        address tokenExpected = weth;
        address token = engine.getCollateralToken(0);

        // Price Feed
        address priceFeedExpected = ethUsdPriceFeed;
        address priceFeed = engine.getPriceFeed(token);

        // Decentralized Stable Coin
        address dscAddressExpected = address(dsc);
        address dscAddress = engine.getAddressDSC();

        assertEq(priceFeed, priceFeedExpected);
        assertEq(token, tokenExpected);
        assertEq(dscAddress, dscAddressExpected);
    }
}
