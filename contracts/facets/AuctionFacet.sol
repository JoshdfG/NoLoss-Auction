// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibError} from "../libraries/LiError.sol";
import {FeeCalculator} from "../libraries/LibFeeCalculator.sol";

contract AuctionFaucet {
  LibAppStorage.Layout internal l;
    ///started here


    function auctionNft(uint _tokenId, uint _price, address _contractNft, uint auctionDuration) external{
      l.Id =  _ID;
      _ID = _ID + 1;
      LibAppStorage.NFT storage nft = l.DisplayNftDetails[ID_];
      nft.userNftID_ = _tokenId;
      nft.userValue_ = _price;
      nft.ownerNft_ = msg.sender;
      nft.contractAddress =  _contractNft;
      nft.auctionDuration_ = _auctionDuration;
    }

function bid(uint _amount, uint _id) external {
    if (block.timestamp > l.auctionEndTime) revert LibError.AUCTION_ALREADY_ENDED();

    LibAppStorage.NFT storage nft = l.DisplayNftDetails[_id];

    // Calculate fees using the helper function
    (uint burnFee, uint daoFee, uint outbidRefund, uint teamFee, uint userFee) = FeeCalculator.calculateFees(_amount);

    if (_amount <= l.bid) revert LibError.BID_TOO_LOW();
    
    if (_amount <= l.highestBid) revert LibError.BID_NOT_HIGH_ENOUGH(l.highestBid);

    // Update highest bidder and bid amount
    l.highestBidder = msg.sender;
    l.highestBid = _amount;

    // Transfer bid amount plus fees to the contract
    require(
        LibAppStorage.transferFrom(msg.sender, address(this), _amount + (burnFee + daoFee + outbidRefund + teamFee + userFee)),
        "Transfer failed"
    );

    // Burn fee
    // Assuming a function burn(uint _amount) to handle the burning
    burn(FeeCalculator.burnFee);

    // Transfer fee to a random DAO address
    // Assuming a function sendToRandomDAO(uint _amount) to handle this
    sendToRandomDAO(FeeCalculator.daoFee);

    // Refund outbid bidder
    refundOutbidBidder(l.secondHighestBidder, FeeCalculator.outbidRefund);

    // Send fee to the team wallet
    // Assuming a function sendToTeamWallet(uint _amount) to handle this
    sendToTeamWallet(FeeCalculator.teamFee);

    sendToLastInteractedAddress(FeeCalculator.userFee);

    emit LibAppStorage.HighestBidIncreased(msg.sender, _amount);
}

// Burn fee
function burn(uint _amount) internal {
    token.transfer(address(0), _amount);

}

// Transfer fee to a random DAO address
function sendToRandomDAO(uint _amount) internal {
    token.transfer(address(0x), _amount);
}

// Refund outbid bidder
function refundOutbidBidder(address _bidder, uint _amount) internal {
    _bidder.transfer(_amount);
}

// Send fee to the team wallet
function sendToTeamWallet(uint _amount) internal {
    teamWallet.transfer(_amount);
}

// Send fee to the last address to interact with AUCToken
function sendToLastInteractedAddress(uint _amount) internal {

}


    function endAuction() external {
        if (block.timestamp < l.auctionEndTime) revert AUCTION_STILL_OPEN();

        if (l.auctionEnded) revert LibError.AUCTION_ALREADY_ENDED();

        l.auctionEnded = true;

        emit LibAppStorage.AuctionEnded(l.highestBidder, l.highestBid);

    }
}
