// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngineBaseTest} from "./BaseTest.t.sol"; 
import {
    ERC20Mock
} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";

contract DSCEngineBurnDSCTest is DSCEngineBaseTest {

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public override {
        super.setUp();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    function collateralAndMint() public {
        uint256 amountToMint = 5000 ether;
        uint256 collateralDeposited = 5 ether;

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        dsce.depositCollateral(weth, collateralDeposited);
        dsce.mintDSC(amountToMint);
        vm.stopPrank();
    }

    /////////////////
    // Sad Path
    /////////////////

    function testRevertNotEnoughMinted() public{
        uint256 amountToRedeem = 2 ether;
        uint256 amountToBurn = 1 ether;

        vm.expectRevert(DSCEngine.DSCEngine__NotEnoughMinted.selector);
        dsce.redeemCollateralForDSC(weth, amountToRedeem, amountToBurn);
    }

    function testRevertNotEnoughCollateral() public {
        uint256 amountToRedeem = 10 ether;
        uint256 amountToBurn = 2000 ether;

        collateralAndMint();

        vm.startPrank(USER);
        ERC20Mock(address(dsc)).approve(address(dsce), 5000 ether);
        vm.expectRevert(DSCEngine.DSCEngine__NotEnoughCollateral.selector);
        dsce.redeemCollateralForDSC(weth, amountToRedeem, amountToBurn);
        vm.stopPrank();
    }
    

    /////////////////
    // Happy Path
    /////////////////

    function testBurnDSCWorks() public {

        uint256 amountDscToBurn = 50 ether;

        collateralAndMint();

        vm.startPrank(USER);
        ERC20Mock(address(dsc)).approve(address(dsce), 5000 ether);
        dsce.burnDSC(amountDscToBurn);
        vm.stopPrank();

        uint256 amountDscExpected = 4950 ether;
        uint256 amountDsc = dsce.getDscMinted(USER);

        assertEq(amountDsc, amountDscExpected);

    }

    // Continuar con el redeem collateral aqui, porque usamos funciones que usa el redeem: deposit, mint, burn

    function testRedeemCollateralWorks() public {

        uint256 amountToRedeem = 2 ether;
        uint256 amountToBurn = 2000 ether;

        collateralAndMint();

        vm.startPrank(USER);
        ERC20Mock(address(dsc)).approve(address(dsce), 5000 ether);
        dsce.redeemCollateralForDSC(weth, amountToRedeem, amountToBurn);
        vm.stopPrank();

        uint256 amountRemainMintedExpected = 3000 ether;
        uint256 amountRemainMinted = dsce.getDscMinted(USER);

        assertEq(amountRemainMinted, amountRemainMintedExpected);

    }
    
}
