// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Funoken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    struct TokenBid{
        bool forSale;
        bool beenBid;
        uint256 highestBid;
        address highestBidder;
        uint auctionStart;
    }
    TokenBid newBid;
     
    mapping (uint256 => TokenBid) idToBid;
    
    modifier upForSale (uint256 _itemId) {
        require(idToBid[_itemId].forSale);
        _;
    }
    modifier onlyOwner (uint256 _itemId){
        require(msg.sender == ownerOf(_itemId));
        _;
    }
    
    constructor() ERC721("Funoken", "FTK") {}
    
    function mintToken(address recipient, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        newBid = TokenBid(false, false, 0, address(0), 0);
        idToBid[newItemId] = newBid;
        return newItemId;
    }
    
    function auction(uint256 itemId, uint256 amount) public onlyOwner(itemId) {
        idToBid[itemId].forSale = true;
        idToBid[itemId].highestBid = amount;
        idToBid[itemId].auctionStart = block.timestamp;
    }
    
    function bid(uint256 itemId) public payable upForSale(itemId){
        require(msg.value> idToBid[itemId].highestBid, "Bid must be higher"); 
        require(msg.sender != ownerOf(itemId));
        
        if(idToBid[itemId].beenBid){
            payable(idToBid[itemId].highestBidder).transfer(idToBid[itemId].highestBid);
        }
        idToBid[itemId].highestBid = msg.value;
        idToBid[itemId].highestBidder = msg.sender;
        idToBid[itemId].beenBid = true;
    }
    
    function endAuction(uint256 itemId) public upForSale(itemId){
        require(block.timestamp > idToBid[itemId].auctionStart + 86400 seconds, "Auction time has not ended yet");
        
        if (idToBid[itemId].beenBid){
            payable(ownerOf(itemId)).transfer(idToBid[itemId].highestBid);
            transferFrom(ownerOf(itemId), idToBid[itemId].highestBidder, itemId);
        }
        idToBid[itemId].forSale = false;
        idToBid[itemId].beenBid = false;
        idToBid[itemId].highestBid = 0;
        idToBid[itemId].highestBidder = address(0);    

    }
}