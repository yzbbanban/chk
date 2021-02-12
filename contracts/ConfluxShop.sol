pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "./SponsorWhitelistControl.sol";


interface TicketNft{
    function mint(address player) external returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface Invite{
    function getUserSimpleInfo(address _address) view external returns(address referrer);
}

contract ConfluxShop{

    event BuyTicket(address buyer, uint256 tokenId);
    event CancelShell(address seller, uint256 tokenId, uint256 price);
    event AddTicketCount(uint256 count);
    event BuySellerTicket(address seller,address buyer,uint256 tokenId,uint256 price);
    event SellTicker(address seller,uint256 tokenId,uint256 price);

    using SafeMath for uint256;

    address ticketShopOwner;

    TicketNft ticketNft;

    uint256 public totalTicket = 1000;

    uint256[] public shopIds;

    mapping(uint256 => Shop) public shopMap;
    mapping(uint256 => uint256) public _allTokensIndex;

    mapping(address => mapping(uint256 => uint256)) public sellerIndex;
    mapping(address => uint256[]) public sellerShops;

    address public platform;
    //2.5  -> 25/1000
    uint256 rate = 25;

    struct Shop{
        address seller;
        uint256 price;
        address buyer;
    }

    modifier onlyOwner(){
        require(msg.sender == ticketShopOwner,"Not owner");
        _;
    }

    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor(address _ticketNft) public{
        ticketShopOwner = msg.sender;
        ticketNft = TicketNft(_ticketNft);
        platform = msg.sender;

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    function getSellerShop(address _seller) view public returns(uint256[] memory _ids){
        return sellerShops[_seller];
    }

    function getShopItems() view public returns(uint256[] memory _shopIds){
        return shopIds;
    }

    function setTokenParam(TicketNft _ticketNft) public onlyOwner(){
        ticketNft = TicketNft(_ticketNft);
    }

    function setPlatForm(address _platform) public onlyOwner(){
        platform = _platform;
    }

    function setPlatFormRate(uint256 _rate) public onlyOwner(){
        rate = _rate;
    }

    function sellTicker(uint256 _tokenId,uint256 _price) public{
        Shop storage shop = shopMap[_tokenId];
        shop.seller = msg.sender;
        shop.buyer = address(0);
        shop.price = _price;
        _allTokensIndex[_tokenId] = shopIds.length;
        shopIds.push(_tokenId);
        transfer1155(msg.sender,address(this),_tokenId);
        //add to seller
        sellerIndex[msg.sender][_tokenId] = sellerShops[msg.sender].length;
        sellerShops[msg.sender].push(_tokenId);
        emit SellTicker(msg.sender, _tokenId, _price);
    }

    function buySellerTicket(uint256 _tokenId) payable public{
        Shop storage shop=shopMap[_tokenId];
        uint256 _price = msg.value;
        require(shop.seller!=msg.sender,"Can not buy self");
        require(_price==shop.price,"Price wrong");
        address(uint160(platform)).transfer(_price.mul(rate).div(1000));
        address(uint160(shop.seller)).transfer(_price.mul(1000-rate).div(1000));
        //1155
        transfer1155(address(this),msg.sender,_tokenId);
        emit BuySellerTicket(shop.seller, msg.sender, _tokenId, _price);
        shop.buyer = msg.sender;
        _removeTokenFromShop(_tokenId);
        //remove seller
        _removeTokenFromSellerShop(shop.seller,_tokenId);
    }

    function cancelShell(uint256 _tokenId) public{
        Shop storage shop=shopMap[_tokenId];
        require(shop.seller == msg.sender,"Only seller");
        transfer1155(address(this),msg.sender,_tokenId);
        emit CancelShell(shop.seller,_tokenId,shop.price);
        _removeTokenFromShop(_tokenId);
        _removeTokenFromSellerShop(shop.seller,_tokenId);
    }

    function _removeTokenFromSellerShop(address _seller, uint256 _tokenId) private {
        // sellerIndex[_seller][_tokenId] = sellerShops[_seller].length;
        // sellerShops[_seller].push(_tokenId);
        uint256 lastTokenIndex = sellerShops[_seller].length.sub(1);
        uint256 tokenIndex = sellerIndex[_seller][_tokenId];

        uint256 lastTokenId = sellerShops[_seller][lastTokenIndex];

        sellerShops[_seller][tokenIndex] = lastTokenId;
        sellerIndex[_seller][lastTokenId] = tokenIndex;

        sellerShops[_seller].pop();
        sellerIndex[_seller][_tokenId] = 0;
    }

    function _removeTokenFromShop(uint256 _tokenId) private {
        uint256 lastTokenIndex = shopIds.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[_tokenId];

        uint256 lastTokenId = shopIds[lastTokenIndex];

        shopIds[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        shopIds.pop();
        _allTokensIndex[_tokenId] = 0;
    }

    function transferEth(address _address, uint256 _value) internal{
        (bool res, ) = address(uint160(_address)).call{value:_value}("");
        require(res,"TRANSFER ETH ERROR");
    }

    function transfer1155(address _from,address _to,uint256 _tokenId) internal{
        ticketNft.safeTransferFrom(_from,_to,_tokenId,1,"");
    }

     //-----------
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )external returns(bytes4){
       return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )external returns(bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
