// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngineBaseTest} from "./BaseTest.t.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";
import {
    ERC20Mock
} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";


contract DSCEngineMintDSCTest is DSCEngineBaseTest {

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public override {
        super.setUp();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /////////////
    // Sad Path
    /////////////

    function testRevertNoCollateralBreaksHealthFactor() public {

        uint256 amountToMint = 2 ether;
        uint256 expectedHealthFactor = 0;

        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine_BreaksHealthFactor.selector, expectedHealthFactor));
        dsce.mintDSC(amountToMint);
    }

    /////////////////
    // Happy Path
    /////////////////

    function collateralAndMint() public {
        uint256 amountToMint = 500 ether;
        uint256 collateralDeposited = 5 ether;

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        dsce.depositCollateral(weth, collateralDeposited);
        dsce.mintDSC(amountToMint);
        vm.stopPrank();
    }

    function testMintDSCWorks() public {
        uint256 usdTokenExpected = 10000e18;
        uint256 tokenAmountExpected = 5 ether;

        collateralAndMint();

        uint256 tokenAmount = dsce.getTokenAmountFromUsd(weth, usdTokenExpected);

        assertEq(tokenAmount, tokenAmountExpected);
    }
}
