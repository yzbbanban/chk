pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
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

interface Chicken20 is IERC777{
    function addTokens(address _address,uint256 _amount) external;
}

interface Invite{
    function getUserSimpleInfo(address _address) view external returns(address referrer);
}

contract TicketShop{

    event BuyTicket(address buyer, uint256 tokenId);
    event CancelShell(address seller, uint256 tokenId, uint256 price);
    event AddTicketCount(uint256 count);
    event BuySellerTicket(address seller,address buyer,uint256 tokenId,uint256 price);
    event SellTicker(address seller,uint256 tokenId,uint256 price);

    using SafeMath for uint256;

    address ticketShopOwner;

    TicketNft ticketNft;

    Invite invite;

    Chicken20 chicken20;

    uint256 public totalTicket = 1000;

    uint256[] public shopIds;

    mapping(uint256 => Shop) public shopMap;
    mapping(uint256 => uint256) public _allTokensIndex;

    address public platform;

    uint256 public ticketPrice = 100e18;

    uint256 rate = 5;

    struct Shop{
        address seller;
        uint256 price;
        address buyer;
    }

    modifier onlyOwner(){
        require(msg.sender == ticketShopOwner,"Not owner");
        _;
    }

    IERC1820Registry private _erc1820 = IERC1820Registry(0x88887eD889e776bCBe2f0f9932EcFaBcDfCd1820);

    // keccak256("ERC777TokensRecipient")
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor(address _ticketNft, Invite _invite, Chicken20 _chicken20) public{
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        ticketShopOwner = msg.sender;
        ticketNft = TicketNft(_ticketNft);
        invite = _invite;
        chicken20 = _chicken20;
        platform = msg.sender;

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    function getShopItems() view public returns(uint256[] memory _shopIds){
        return shopIds;
    }

    function setTokenParam(TicketNft _ticketNft, Invite _invite, Chicken20 _chicken20) public onlyOwner(){
        ticketNft = TicketNft(_ticketNft);
        invite = _invite;
        chicken20 = _chicken20;
    }

    function setTickPrice(uint256 _ticketPrice) public onlyOwner(){
        ticketPrice = _ticketPrice;
    }

    function setPlatForm(address _platform) public onlyOwner(){
        platform = _platform;
    }

    function setPlatFormRate(uint256 _rate) public onlyOwner(){
        rate = _rate;
    }

    function sellTicker(uint256 _tokenId,uint256 _price) public{
        require(_price >= ticketPrice,"Price must larger than ticket price");
        Shop storage shop = shopMap[_tokenId];
        shop.seller = msg.sender;
        shop.buyer = address(0);
        shop.price = _price;
        _allTokensIndex[_tokenId] = shopIds.length;
        shopIds.push(_tokenId);
        transfer1155(msg.sender,address(this),_tokenId);
        emit SellTicker(msg.sender, _tokenId, _price);
    }

    function buySellerTicket(uint256 _tokenId) payable public{
        Shop storage shop=shopMap[_tokenId];
        uint256 _price = msg.value;
        require(shop.seller!=msg.sender,"Can not buy self");
        require(_price==shop.price,"Price wrong");
        address(uint160(platform)).transfer(_price.mul(rate).div(100));
        address(uint160(shop.seller)).transfer(_price.mul(100-rate).div(100));
        //721
        // ticketNft.transferFrom(address(this), msg.sender, _tokenId);
        //1155
        transfer1155(address(this),msg.sender,_tokenId);
        emit BuySellerTicket(shop.seller, msg.sender, _tokenId, _price);
        shop.buyer = msg.sender;
        _removeTokenFromShop(_tokenId);
    }

    function buyTicket() payable public{
        require(totalTicket > 0,"No ticket, sell out");
        require(msg.value == ticketPrice,"No ticket, sell out");
        // nft 1155
        uint256 _tokenId = ticketNft.mint(msg.sender);
        totalTicket = totalTicket.sub(1);
        uint256 am = 0;
        address parent = invite.getUserSimpleInfo(msg.sender);
        if(parent!=address(0)){
            transferEth(parent,ticketPrice.mul(6).div(100));
            address grandparent = invite.getUserSimpleInfo(parent);
            am = 6;
            if(parent!=address(0)){
                transferEth(grandparent,ticketPrice.mul(4).div(100));
                am = 10;
            }
        }
        transferEth(platform,ticketPrice.mul(100-am).div(100));
        chicken20.addTokens(msg.sender,5e18);
        emit BuyTicket(msg.sender,_tokenId);
    }

    function cancelShell(uint256 _tokenId) public{
        Shop storage shop=shopMap[_tokenId];
        require(shop.seller == msg.sender,"Only seller");
        transfer1155(address(this),msg.sender,_tokenId);
        emit CancelShell(shop.seller,_tokenId,shop.price);
        _removeTokenFromShop(_tokenId);
    }

    function addTicketCount(uint256 _count) public onlyOwner{
        totalTicket= totalTicket.add(_count);
        emit AddTicketCount(_count);
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
