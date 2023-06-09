// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Check out https://github.com/Fantom-foundation/Artion-Contracts/blob/5c90d2bc0401af6fb5abf35b860b762b31dfee02/contracts/FantomMarketplace.sol
// For a full decentralized nft marketplace

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();


contract NftMarketplace is ReentrancyGuard {

  struct Listing {
        uint256 price;
        address seller;
  }

  event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
  );

  event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
  );

  event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
  );
  

  mapping(address => mapping(uint256 => Listing)) private s_listings;
  
  mapping(address => uint256) private s_proceeds;

  modifier notListed(
    //状态1 
    //防止 nft 被重复上线
        address nftAddress,
        uint256 tokenId
  ) {
      Listing memory listing = s_listings[nftAddress][tokenId];
      if (listing.price > 0) {
          revert AlreadyListed(nftAddress, tokenId);
      }
      _;
  }

  modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
  }

  modifier isListed(address nftAddress, uint256 tokenId) {
    //在购买nft之前，确认nft是否上线商城
    Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price <= 0) {
        revert NotListed(nftAddress, tokenId);
    }
    _;
  }

  function listItem(
    //展示nft
    address nftAddress,
    uint256 tokenId,
    uint256 price

    )   external
      notListed(nftAddress, tokenId)
      isOwner(nftAddress, tokenId, msg.sender)
    {

    if (price <= 0) {
        revert PriceMustBeAboveZero();
    }
    //用户需要批准，不批准售卖就返回一个错误;即  你确定上线么？？？？
    IERC721 nft = IERC721(nftAddress);
    if (nft.getApproved(tokenId) != address(this)) {
        revert NotApprovedForMarketplace();
    }
    s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
    emit ItemListed(msg.sender, nftAddress, tokenId, price);

  }

  function buyItem(address nftAddress, uint256 tokenId)
    external 
    payable
    isListed(nftAddress, tokenId)
    nonReentrant
     {
    Listing memory listedItem = s_listings[nftAddress][tokenId];
    if (msg.value < listedItem.price) {
        revert PriceNotMet(nftAddress, tokenId, listedItem.price);
    
    }
    s_proceeds[listedItem.seller] += msg.value;
      
    delete (s_listings[nftAddress][tokenId]);
    IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
  }

  function cancelListing(address nftAddress, uint256 tokenId)
    external
    isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
  {
      delete (s_listings[nftAddress][tokenId]);
      emit ItemCanceled(msg.sender, nftAddress, tokenId);
  }

  function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        nonReentrant
        isOwner(nftAddress, tokenId, msg.sender)
    {
        //We should check the value of `newPrice` and revert if it's below zero (like we also check in `listItem()`)
        if (newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
  }
  
  function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
  }

  function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
  }

  function getProceeds(address seller) external view returns (uint256) {
      return s_proceeds[seller];
  }


}