pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "../interfaces/IERC721.sol";

contract AuctionFacet {
    LibAppStorage.Layout internal l;

    function createAuction(
        address _contractAddress,
        uint _tokenId,
        uint _startingPrice,
        uint _auctionEndTime
    ) external {
        require(_contractAddress != address(0), "INVALID_CONTRACT_ADDRESS");
        require(
            IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender,
            "NOT_OWNER"
        );
        require(_auctionEndTime > block.timestamp, "INVALID_CLOSE_TIME");
        IERC721(_contractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        LibAppStorage.Auction memory _newAuction = LibAppStorage.Auction({
            id: l.auctions.length,
            author: msg.sender,
            tokenId: _tokenId,
            startingPrice: _startingPrice,
            closeTime: _auctionEndTime,
            nftContractAddress: _contractAddress,
            closed: false
        });
        l.auctions.push(_newAuction);
    }

    function calculatePercentageCut(uint amount) internal pure returns (uint) {
        return (10 * amount) / 100;
    }

    function bid(uint auctionId, uint price) external {
        require(!l.auctions[auctionId].closed, "AUCTION_CLOSED");
        require(
            block.timestamp < l.auctions[auctionId].closeTime,
            "AUCTION_CLOSED"
        );
        require(l.balances[msg.sender] > price, "INSUFFICIENT_BALANCE");

        if (l.bids[auctionId].length == 0) {
            require(
                price >= l.auctions[auctionId].startingPrice,
                "STARTING_PRICE_IS_TOO_LOW_INCREASE_IT!"
            );

            LibAppStorage.Bid memory _newBid = LibAppStorage.Bid({
                author: msg.sender,
                amount: price,
                auctionId: auctionId
            });
            l.bids[auctionId].push(_newBid);
        } else {
            require(
                price > l.bids[auctionId][l.bids[auctionId].length - 1].amount,
                "PRICE_MUST_BE_GREATER_THAN_LAST_BID"
            );

            uint percentageCut = calculatePercentageCut(price);
            LibAppStorage.distributeOutBidFee(
                percentageCut,
                l.bids[auctionId][l.bids[auctionId].length - 1].author,
                l.lastPersonToInteract
            );

            LibAppStorage.Bid memory _newBid = LibAppStorage.Bid({
                author: msg.sender,
                amount: price - percentageCut,
                auctionId: auctionId
            });
            l.bids[auctionId].push(_newBid);
        }
    }

    function closeAuction(uint auctionId) external {
        LibAppStorage.Auction storage auction = l.auctions[auctionId];

        require(!auction.closed, "AUCTION_CLOSED");
        require(block.timestamp >= auction.closeTime, "TIME_NOT_ELAPSED");
        require(
            l.bids[auctionId][l.bids[auctionId].length - 1].author ==
                msg.sender ||
                auction.author == msg.sender,
            "YOU_DONT_HAVE_RIGHT_TO_CLOSE_THE_AUCTION"
        );
        LibAppStorage.transferFrom(
            address(this),
            auction.author,
            l.bids[auctionId][l.bids[auctionId].length - 1].amount
        );

        IERC721(auction.nftContractAddress).transferFrom(
            address(this),
            l.bids[auctionId][l.bids[auctionId].length - 1].author,
            auction.tokenId
        );
    }

    function getAuction(
        uint auctionId
    ) external view returns (LibAppStorage.Auction memory) {
        return l.auctions[auctionId];
    }

    function getBid(
        uint auctionId
    ) external view returns (LibAppStorage.Bid[] memory) {
        return l.bids[auctionId];
    }
}
