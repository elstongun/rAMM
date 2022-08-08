// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {IERC20} from "./OpenZeppelin/IERC20.sol";
import {IOwnable} from "./OpenZeppelin/Interfaces.sol";
import "./OpenZeppelin/SafeERC20.sol";

contract CallOptionBid {
    address public immutable bidfactory;
    address public immutable marketMaker;
    address public immutable issuerControlAddress;
    address public immutable issuerTokenAddress;
    address public immutable usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public immutable amountWantedForTrading;
    uint256 public immutable amountWantedForOption;
    uint256 public immutable strikePriceInUSDC;
    uint256 public immutable fee; // in bps
    bool public hasEnded = false;
    bool public hasAccepted = false;

    event OfferFilled(address buyer, uint256 jewelAmount, address token, uint256 tokenAmount);
    event OfferCanceled(address seller, uint256 jewelAmount);

    constructor(
        address _marketMaker,
        address _issuerControlAddress,
        address _issuerTokenAddress,
        uint256 _amountWantedForTrading,
        uint256 _amountWantedForOption,
        uint256 _strikePriceInUSDC,
        uint256 _fee
    ) {
        bidfactory = msg.sender;
        marketMaker = _marketMaker;
        issuerControlAddress = _issuerControlAddress;
        issuerTokenAddress = _issuerTokenAddress;
        amountWantedForTrading = _amountWantedForTrading;
        amountWantedForOption = _amountWantedForOption;
        strikePriceInUSDC = _strikePriceInUSDC; //in 1e18 scale
        fee = _fee;
    }

    // release trapped funds
    function withdrawTokens(address token) public {
        require(msg.sender == IOwnable(bidfactory).owner());
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(IOwnable(bidfactory).owner()).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(token), IOwnable(bidfactory).owner(), balance);
        }
    }
    
    function acceptBid() public {
        require(IERC20(issuerTokenAddress).balanceOf(issuerControlAddress) >= (amountWantedForOption + amountWantedForTrading));
        require(msg.sender == issuerControlAddress);
        hasAccepted = true;
        SafeERC20.safeTransferFrom(IERC20(issuerTokenAddress), issuerControlAddress, address(this), amountWantedForTrading + amountWantedForOption);
    }

    function acceptCapital() public {
        require(msg.sender == marketMaker);
        require(hasAccepted = true);
        SafeERC20.safeTransfer(IERC20(issuerTokenAddress), marketMaker, amountWantedForTrading);
    }

    function redeemCallOption(uint256 amountToRedeem) public {
        require(msg.sender == marketMaker);
        require(amountToRedeem >= balanceOfOption());
        require(hasEnded == false);

        uint256 usdcOwed = strikePriceInUSDC * amountToRedeem;
        uint256 txFee = mulDiv(amountToRedeem, fee, 10_000);
        uint256 valueMinusFee = amountToRedeem - txFee;

        //Issuer receives their USDC
        SafeERC20.safeTransfer(IERC20(usdc), issuerControlAddress, usdcOwed);
        //Admin receives fee and market maker receives tokens
        SafeERC20.safeTransfer(IERC20(issuerTokenAddress), IOwnable(bidfactory).owner(), txFee);
        SafeERC20.safeTransfer(IERC20(issuerTokenAddress), marketMaker, valueMinusFee);
    }

    function terminate() public {
        require(msg.sender == issuerControlAddress || msg.sender == marketMaker);
        hasEnded = true;
    }

    function returnTradingCapital(uint256 amountToReturn) public {
        require(msg.sender == marketMaker);
        SafeERC20.safeTransfer(IERC20(issuerTokenAddress), issuerControlAddress, amountToReturn);
    }

    function balanceOfOption() public view returns(uint256) {
        return IERC20(issuerTokenAddress).balanceOf(address(this));
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }
}