pragma solidity ^0.8.0;

library LibAppStorage {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    struct UserStake {
        uint256 stakedTime;
        uint256 amount;
    }

    struct Auction {
        uint id;
        address author;
        uint tokenId;
        uint startingPrice;
        uint closeTime;
        address nftContractAddress;
        bool closed;
    }

    struct Bid {
        address author;
        uint amount;
        uint auctionId;
    }

    struct Layout {
        ///AUCTUIN
        Auction[] auctions;
        //BID
        mapping(uint => Bid[]) bids;
        //ERC20
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        address lastPersonToInteract;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        //STAKING
        address rewardToken;
        uint256 rewardRate;
        mapping(address => UserStake) userDetails;
        address[] stakers;
    }

    function layoutStorage() internal pure returns (Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function transferFrom(
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

    function distributeToBurn(uint _amount) internal {
        LibAppStorage.transferFrom(address(0), address(0), _amount); // Sending to burn address
    }

    // Distribute tokens to DAO address
    function distributeToDAO(uint _amount) internal {
        LibAppStorage.transferFrom(
            address(0),
            address(0x42AcD393442A1021f01C796A23901F3852e89Ff3),
            _amount
        ); // Sending to DAO address
    }

    // Distribute tokens to outbid bidder
    function distributeToOutbidBidder(
        address _outbidBidder,
        uint _amount
    ) internal {
        LibAppStorage.transferFrom(address(0), _outbidBidder, _amount); // Sending to outbid bidder
    }

    // Distribute tokens to team address
    function distributeToTeam(uint _amount) internal {
        LibAppStorage.transferFrom(address(0), address(0), _amount); // Sending to team address
    }

    // Distribute tokens to last ERC20 interactor
    function distributeToInteractor(
        address _lastERC20Interactor,
        uint _amount
    ) internal {
        LibAppStorage.transferFrom(address(0), _lastERC20Interactor, _amount); // Sending to last ERC20 interactor
    }

    function distributeOutBidFee(
        uint _tax,
        address _outbidBidder,
        address _lastERC20Interactor
    ) internal {
        // Calculate each portion of the tax
        uint toBurn = (_tax * 20) / 100;
        uint toDAO = (_tax * 20) / 100;
        uint toOutbidBidder = (_tax * 30) / 100;
        uint toTeam = (_tax * 20) / 100;
        uint toInteractor = (_tax * 10) / 100;

        // Distribute each portion of the tax
        LibAppStorage.distributeToBurn(toBurn);
        LibAppStorage.distributeToDAO(toDAO);
        LibAppStorage.distributeToOutbidBidder(_outbidBidder, toOutbidBidder);
        LibAppStorage.distributeToTeam(toTeam);
        LibAppStorage.distributeToInteractor(
            _lastERC20Interactor,
            toInteractor
        );
    }
}
