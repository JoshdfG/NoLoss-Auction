// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

// import "../contracts/facets/LayoutChangerFacet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

import "../contracts/libraries/LibAppStorage.sol";
import "../contracts/facets/AuctionFacet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/Nft.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    AuctionFacet auctionF;
    ERC20Facet erc20Facet;
    Nft nft;

    AuctionFacet boundAuction;
    ERC20Facet boundERC;

    address A = address(0xa);
    address B = address(0xb);
    address C = address(0xc);

    // LayoutChangerFacet lFacet;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        auctionF = new AuctionFacet();
        erc20Facet = new ERC20Facet();
        nft = new Nft();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(auctionF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(erc20Facet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC20Facet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        A = mkaddr("staker a");
        B = mkaddr("staker b");
        C = mkaddr("staker c");

        //mint test tokens
        ERC20Facet(address(diamond)).mintTo(A);
        ERC20Facet(address(diamond)).mintTo(B);

        boundAuction = AuctionFacet(address(diamond));
        boundERC = ERC20Facet(address(diamond));
    }

    //ERROR/REVERT-TEST-CASE
    function testRevertIfTokenAddressIsZero() public {
        vm.expectRevert("INVALID_CONTRACT_ADDRESS");
        boundAuction.createAuction(address(0), 1, 1e18, 2 days);
    }

    function testRevertIfNotTokenOwner() public {
        switchSigner(A);
        nft.mint();
        switchSigner(B);
        vm.expectRevert("NOT_OWNER");
        boundAuction.createAuction(address(nft), 1, 1e18, 2 days);
    }

    function testRevertIfAuctionTimestampIsNotGreaterThanBlockTimestamp()
        public
    {
        switchSigner(A);
        nft.mint();
        vm.expectRevert("INVALID_CLOSE_TIME");
        boundAuction.createAuction(address(nft), 1, 1e18, 1);
    }

    function testAuctionChange() public {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 1e18, 2 days);
        LibAppStorage.Auction memory new_auction = boundAuction.getAuction(0);
        assertEq(new_auction.id, 0);
        assertEq(new_auction.author, A);
        assertEq(new_auction.tokenId, 1);
        assertEq(new_auction.closeTime, 2 days);
        assertEq(new_auction.nftContractAddress, address(nft));
    }

    function testRevertTimeStampExceded() public {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 1e18, 2 days);
        vm.warp(3 days);
        vm.expectRevert("AUCTION_CLOSED");
        boundAuction.bid(0, 5e18);
    }

    function testToRevertOnInsufficientTokenBalance() public {
        switchSigner(C);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 1e18, 2 days);
        vm.expectRevert("INSUFFICIENT_BALANCE");
        boundAuction.bid(0, 5e18);
    }

    function testRevertIfBidAmountIsLessThanAuctionStartPrice() public {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        vm.expectRevert("STARTING_PRICE_IS_TOO_LOW_INCREASE_IT!");
        boundAuction.bid(0, 1e18);
    }

    function testRevertIfBidAmountIsLessThanOrEqualToTheLastBiddedAmount()
        public
    {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        boundAuction.bid(0, 2e18);
        vm.expectRevert("PRICE_MUST_BE_GREATER_THAN_LAST_BID");
        boundAuction.bid(0, 1e18);
    }

    function testRevertIfBidIsCLosed() external {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        boundAuction.bid(0, 2e18);
        vm.expectRevert("TIME_NOT_ELAPSED");
        boundAuction.closeAuction(0);
    }

    function testRevertIfSignerHasNoRightTOCloseBid() external {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        boundAuction.bid(0, 2e18);
        switchSigner(B);
        vm.warp(2 days);
        vm.expectRevert("YOU_DONT_HAVE_RIGHT_TO_CLOSE_THE_AUCTION");
        boundAuction.closeAuction(0);
    }

    function testToConfirmTokenTransferAfterAuctionHasEnded() external {
        ERC20Facet(address(diamond)).mintTo(C);
        switchSigner(A);
        uint oldABalance = boundERC.balanceOf(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        switchSigner(B);
        boundAuction.bid(0, 2e18);
        switchSigner(C);
        boundAuction.bid(0, 3e18);
        vm.warp(2 days);
        boundAuction.closeAuction(0);
        assertEq(
            boundERC.balanceOf(A),
            oldABalance + (3e18 - ((10 * 3e18) / 100))
        );
    }

    //MAIN_FUNCTION_TESTING
    function testPercentageDductionToEnsureNoLoss() public {
        uint oldOutbidderBal = boundERC.balanceOf(A);
        ERC20Facet(address(diamond)).mintTo(C);
        switchSigner(C);
        boundERC.transfer(address(0), 1e18);
        uint oldLastERC20InteractorBal = boundERC.balanceOf(
            boundERC.getLastInteraction()
        );
        switchSigner(A);

        uint oldDaoBal = boundERC.balanceOf(
            0x42AcD393442A1021f01C796A23901F3852e89Ff3
        );
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        boundAuction.bid(0, 2e18);
        switchSigner(B);
        boundAuction.bid(0, 3e18);
        assertEq(
            boundERC.balanceOf(0x42AcD393442A1021f01C796A23901F3852e89Ff3),
            ((2 * 3e18) / 100) + oldDaoBal
        );
        assertEq(boundERC.balanceOf(A), ((3 * 3e18) / 100) + oldOutbidderBal);
        assertEq(boundERC.balanceOf(A), ((3 * 3e18) / 100) + oldOutbidderBal);
        assertEq(
            boundERC.balanceOf(boundERC.getLastInteraction()),
            ((1 * 3e18) / 100) + oldLastERC20InteractorBal
        );
    }

    function testBids() public {
        switchSigner(A);
        nft.mint();
        nft.approve(address(diamond), 1);
        boundAuction.createAuction(address(nft), 1, 2e18, 2 days);
        boundAuction.bid(0, 2e18);
        switchSigner(B);
        boundAuction.bid(0, 3e18);
        LibAppStorage.Bid[] memory bids = boundAuction.getBid(0);
        assertEq(bids.length, 2);
        assertEq(bids[0].author, A);
        assertEq(bids[0].amount, 2e18);
        assertEq(bids[1].author, B);
        assertEq(bids[1].amount, (3e18 - ((10 * 3e18) / 100)));
    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }

    // function testLayoutfacet() public {
    //     LayoutChangerFacet l = LayoutChangerFacet(address(diamond));
    //     // l.getLayout();
    //     l.ChangeNameAndNo(777, "one guy");

    //     //check outputs
    //     LibAppStorage.Layout memory la = l.getLayout();

    //     assertEq(la.name, "one guy");
    //     assertEq(la.currentNo, 777);
    // }

    // function testLayoutfacet2() public {
    //     LayoutChangerFacet l = LayoutChangerFacet(address(diamond));
    //     //check outputs
    //     l.ChangeNameAndNo(777, "one guy");

    //     LibAppStorage.Layout memory la = l.getLayout();

    //     assertEq(la.name, "one guy");
    //     assertEq(la.currentNo, 777);
    // }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
