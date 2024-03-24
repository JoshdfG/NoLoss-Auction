pragma solidity ^0.8.0;

library LibError {
    error AUCTION_STILL_OPEN();

    error BID_NOT_HIGH_ENOUGH(uint highestBid);

    error AUCTION_NOT_ENDED();

    error BID_TOO_LOW();

    error AUCTION_ALREADY_ENDED();
}
