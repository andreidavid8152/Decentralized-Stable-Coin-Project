// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngineBaseTest} from "./BaseTest.t.sol"; 
import {
    ERC20Mock
} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";
import {MockV3Aggregator} from "../../../test/mocks/MockV3Aggregator.sol";

contract DSCEngineLiquidateTest is DSCEngineBaseTest {

    address public DEBTOR = makeAddr("debtor");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public override {
        super.setUp();

        ERC20Mock(weth).mint(DEBTOR, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, 20 ether);
    }


    // We need 2 persons - 1 Debtor - 2 liquidator

    function collateralMintDebtor() public {
        uint256 amountToMint = 5000 ether;
        uint256 collateralDeposited = 5 ether;

        vm.startPrank(DEBTOR);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        dsce.depositCollateral(weth, collateralDeposited);
        dsce.mintDSC(amountToMint);
        vm.stopPrank();
    }


    function collateralMintLiquidator() public {
        uint256 amountToMint = 5100 ether;
        uint256 collateralDeposited = 15 ether;

        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(dsce), 15 ether);
        dsce.depositCollateral(weth, collateralDeposited);
        dsce.mintDSC(amountToMint);
        vm.stopPrank();
    }

    /////////////////
    // Sad Path
    /////////////////

    function testRevertGoodHealthFactor() public {

        uint256 debtToCoverOfDebtor = 1000 ether;
        
        collateralMintDebtor();

        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        dsce.liquidate(weth, DEBTOR, debtToCoverOfDebtor);
    }

    function testRevertHealthFactorNotImproved() public {

        uint256 debtToCoverOfDebtor = 2500 ether;

        collateralMintDebtor();
        collateralMintLiquidator();

        // Manipulacion pricefeed
        int256 updatedPrice = 1000e8; 
        address ethUsdPriceFeed = dsce.getPriceFeed(weth);
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(updatedPrice);

        vm.startPrank(LIQUIDATOR);
        ERC20Mock(address(dsc)).approve(address(dsce), 5000 ether);

        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        dsce.liquidate(weth, DEBTOR, debtToCoverOfDebtor);
        vm.stopPrank();
    }

    /////////////////
    // Happpy Path
    /////////////////

    function testLiquidateWorks() public {
        // 1. Liquidador y deudor (deposit y mint)
        collateralMintDebtor();
        collateralMintLiquidator();

        // 2. Crash del precio
        int256 updatedPrice = 1750e8; 
        address ethUsdPriceFeed = dsce.getPriceFeed(weth);
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(updatedPrice);

        // 3. Liquidación
        vm.startPrank(LIQUIDATOR);
        uint256 debtToCoverOfDebtor = 2500 ether;
        ERC20Mock(address(dsc)).approve(address(dsce), debtToCoverOfDebtor);
        
        dsce.liquidate(weth, DEBTOR, debtToCoverOfDebtor);
        vm.stopPrank();

        // 4. Comprobacion
        uint256 mintedExpectedRemainNoLongerDebtor = 2500 ether;
        uint256 mintedRemainNoLongerDebtor = dsce.getDscMinted(DEBTOR);

        assertEq(mintedRemainNoLongerDebtor, mintedExpectedRemainNoLongerDebtor);
    }
}