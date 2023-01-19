// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC721Extensions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract market is Ownable {
    IERC20 token;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; //total number of items ever created
    Counters.Counter private _itemsSold; //total number of items sold
    IERC721Extensions park;

    constructor(address _park) {
        park = IERC721Extensions(_park);
    }

    mapping (uint => address) _whiteList; // mapping 타입으로 바꾸기 (tokenid -> whitelist)
    mapping (uint256 => MarketItem) private idMarketItem; //a way to access values of the MarketItem struct above by passing an integer ID

    struct MarketItem {
        uint itemId;
        uint256 tokenId;
        address payable seller; //person selling the nft
        address payable owner; //owner of the nft
        uint256 price;
        bool sold;
    }

    //log message (when Item is sold)
    event MarketItemCreated (
        uint indexed itemId,
        uint256 indexed tokenId,
        address  seller,
        address  owner,
        uint256 price,
        bool sold
    );

    function setToken (address tokenAddress) public onlyOwner returns (bool) {
        require(tokenAddress != address(0x0));
        token = IERC20(tokenAddress);
        return true;
    }

    function listing(address owner, uint256 tokenId, uint _cost) public {
        uint Origin_cost = park.getOriginCost(tokenId);
        require(_cost < Origin_cost);
        if(!park.isApprovedForAll(owner, address(this))) {
            park.approvalForAllProxy(owner,address(this));
        }

        _itemIds.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _itemIds.current();

        idMarketItem[tokenId] = MarketItem(
            itemId,
            tokenId,
            payable(owner), //address of the seller putting the nft up for sale
            payable(address(0)), //no owner yet (set owner to empty address)
            _cost,
            false
        );

        emit MarketItemCreated(
            itemId,
            tokenId,
            owner,
            address(0),
            _cost,
            false
        );
    }

    function whiteListing(address owner, address to, uint256 tokenId, uint _cost) public {
        _whiteList[tokenId] = to; 
        uint Origin_cost = park.getOriginCost(tokenId);
        require(_cost < Origin_cost);
        if(!park.isApprovedForAll(owner, address(this))) {
            park.approvalForAllProxy(owner,address(this));
        }

        _itemIds.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _itemIds.current();

        idMarketItem[tokenId] = MarketItem(
            itemId,
            tokenId,
            payable(owner), //address of the seller putting the nft up for sale
            payable(address(0)), //no owner yet (set owner to empty address)
            _cost,
            false
        );

        emit MarketItemCreated(
            itemId,
            tokenId,
            owner,
            address(0),
            _cost,
            false
        );
    }

    function publicPurchase(address owner, address to, uint256 tokenId, uint _cost) public {
        park.transferFrom(owner, to, tokenId);
        token.transferFrom(owner, to, _cost);

        idMarketItem[tokenId].owner = payable(to); //mark buyer as new owner
        idMarketItem[tokenId].sold = true; //mark that it has been sold
        _itemsSold.increment(); //increment the total number of Items sold by 1
    }

    function privatePurchase(address owner, address to, uint256 tokenId, uint _cost) public {
        require(_whiteList[tokenId]==to);
        park.transferFrom(owner, to, tokenId);
        delete _whiteList[tokenId];
        token.transferFrom(owner, to, _cost);

        idMarketItem[tokenId].owner = payable(to); //mark buyer as new owner
        idMarketItem[tokenId].sold = true; //mark that it has been sold
        _itemsSold.increment(); //increment the total number of Items sold by 1
    }

}