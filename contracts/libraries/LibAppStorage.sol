pragma solidity ^0.8.0;

library LibAppStorage {
    struct Layout {
        uint256 currentNo;
        string name;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    struct UserStake {
        uint256 stakedTime;
        uint256 amount;
        uint256 allocatedPoints;
    }

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event HighestBidIncreased(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    struct Layout {
        //ERC20
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        // auction
        mapping(address => NFT) DisplayNftDetails;
        //BIDDING
        address highestBidder;
        uint highestBid;
        uint auctionEndTime;
        bool auctionEnded;
        uint bid;
        mapping(address => uint) DisplayBidAmount;
        uint Id;
    }

    struct NFT {
        uint userNftID_;
        uint userValue_;
        address ownerNft_;
        uint auctionDuration_;
        address contractAddress;
    }

    function layoutStorage() internal pure returns (Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        Layout storage l = layoutStorage();
        uint256 frombalances = l.balances[msg.sender];
        require(
            frombalances >= _amount,
            "ERC20: Not enough tokens to transfer"
        );
        l.balances[_from] = frombalances - _amount;
        l.balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }
}
