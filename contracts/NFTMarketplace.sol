// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./utils/Counters.sol";
import "hardhat/console.sol";

contract NFTmarketplace is
    ERC721URIStorage // This means NFTMarketplace inherits from the ERC721 contract.
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; //every nft will have a unique id
    Counters.Counter private _itemsSold; // how many tokens have been sold

    uint256 listingPrice = 0.0025 ether;

    address payable owner; // owner of the contract

    mapping(uint256 => MarketItem) private idToMarketItem; // mapping from token id to market item

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner of the marketplace can change the listing price"
        );
        _;
    }

    constructor() ERC721("NFT Metaverse Token", "MYNFT") {
        // initializing the ERC721 contract similar to  => class NFTMarketplace extends ERC721 {
        owner = payable(msg.sender);
    }

    function upddateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // CREATE NFT TOKEN FUNCTION

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        // return token id

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    function resaleToken(uint256 tokenId, uint256 price) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender, "You aint own this NFT");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // function to be called when a user wants to buy a token
    function createMarketSale(uint256 tokenId) public payable{
        uint256 price = idToMarketItem[tokenId].price;

        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].owner = payable(address(0));

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idToMarketItem[tokenId].seller).transfer(price);

    }

    function fetchUnsoldNFTs() public view returns(MarketItem[] memory){
        uint256 totalItemsCount = _tokenIds.current();
        uint256 unsoldItemsCount = totalItemsCount - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory unsoldItems = new MarketItem[](unsoldItemsCount);
        for(uint256 i = 0; i < totalItemsCount; i++){
            if(idToMarketItem[i + 1].owner == address(this)){
                uint256 currentId = idToMarketItem[i + 1].tokenId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                unsoldItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return unsoldItems;
    }

    function fetchUserNFTS() public view returns(MarketItem[] memory){
        uint256 totalItemsCount = _tokenIds.current();
        uint256 userItemsCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalItemsCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                userItemsCount += 1;
            }
        }

        MarketItem[] memory userItems = new MarketItem[](userItemsCount);
        for(uint256 i = 0; i < totalItemsCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                uint256 currentId = idToMarketItem[i + 1].tokenId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                userItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return userItems;
    }
  
}
