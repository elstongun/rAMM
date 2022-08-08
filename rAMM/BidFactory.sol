// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {Ownable} from "./OpenZeppelin/Ownable.sol";
import {CallOptionBid} from "./CallOptionBid.sol";
import {RetainerBid} from "./RetainerBid.sol";

//create market maker array to create bids and require the caller be on it
contract BidFactory is Ownable {
    uint256 public fee = 1000; // in bps
    CallOptionBid[] public callOptionBids;
    RetainerBid[] public retainerBids;
    mapping(address => bool) marketMakers;

    event CallOptionBidCreated(address optionBid, address issuerTokenAddress, uint256 amountWanted);
    event RetainerBidCreated(address retainerBid, address issuerTokenAddress, uint256 amountWanted);

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function addAMarketMaker(address marketMaker) public onlyOwner returns(address) {
        marketMakers[marketMaker] = true;
        return marketMaker;
    }

    function removeMarketMaker(address marketMaker) public onlyOwner returns(address) {
        require(marketMakers[marketMaker] = true);
        marketMakers[marketMaker] = false;
        return marketMaker;
    }

    function createCallOptionBid(address _issuerControlAddress, address _issuerTokenAddress, uint256 _amountWantedForTrading, uint256 _amountWantedForOption, uint256 _strikePriceInUSD) public returns (RetainerBid) {
        require(marketMakers[msg.sender] == true);
        CallOptionBid optionBid = new CallOptionBid(msg.sender, _issuerControlAddress, _issuerTokenAddress, _amountWantedForTrading, _amountWantedForOption, _strikePriceInUSD, fee);
        callOptionBids.push(optionBid);
        emit CallOptionBidCreated(address(optionBid), _issuerTokenAddress, _amountWantedForTrading, _amountWantedForOption, _strikePriceInUSD);
        return optionBid;
    }

    function createRetainerBid(address _issuerTokenAddress, address _issuerControlAddress, uint256 _amountWanted) public returns (RetainerBid) {
        require(marketMakers[msg.sender] == true);
        RetainerBid retainerBid = new RetainerBid(msg.sender, _issuerControlAddress, _issuerTokenAddress, _amountWanted, fee);
        retainerBids.push(retainerBid);
        emit RetainerBidCreated(address(retainerBid), _issuerTokenAddress, _amountWanted);
        return retainerBid;
    }
    
    function getActiveOptionBids() public view returns (CallOptionBid[] memory) {
        return callOptionBids;
    }
    
    function getActiveOptionBids() public view returns (RetainerBid[] memory) {
        return retainerBids;
    }

    function setFee(uint256 newFee) public onlyOwner returns(uint256) {
        fee = newFee;
        return newFee;
    }
}