pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // Create a payable buyTokens() function:
  function buyTokens() public payable returns (uint256) {
    require(msg.value > 0, "Must be an amount greater than 0");
    uint256 buyAmount = msg.value * tokensPerEth;

    require(yourToken.balanceOf(address(this)) >= buyAmount, "Vendor does not have enough tokens");
    (bool sent) = yourToken.transfer(msg.sender, buyAmount);
    require(sent, "Failed to transfer token");

    emit BuyTokens(msg.sender, msg.value, buyAmount);
    return buyAmount;
  }

  // Create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    (bool sent,) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to withdraw");
  }

  // Create a sellTokens() function:
  function sellTokens(uint256 sellAmount) public {
    require(sellAmount > 0, "Cannot sell an amount of 0");
    require(yourToken.balanceOf(msg.sender) >= sellAmount, "Cannot sell more than you have");

    uint256 ethTransferAmount = sellAmount / tokensPerEth;
    require(address(this).balance >= ethTransferAmount, "Vendor does not have enough funds");

    (bool sent) = yourToken.transferFrom(msg.sender, address(this), sellAmount);
    require(sent, "Failed to transfer to vendor");

    (sent,) = msg.sender.call{value: ethTransferAmount}("");
    require(sent, "Failed to send to user");

    emit SellTokens(msg.sender, sellAmount, ethTransferAmount);
  }

  receive() external payable {}
  fallback() external payable {}
}
