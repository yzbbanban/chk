pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import './Ticket1155Nft.sol';

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "./SponsorWhitelistControl.sol";

contract SnatchNormal is IERC777Recipient{

    event AddSnatch(address owner,uint256 _id);
    event SnatchTokenPool(address _addr,uint256 _amount);
    event WithdrawTokenPool(address _owner, address _addr,uint256 _amount);

    mapping(address => Ticket1155Nft) ticketMap;

    mapping (address=>uint256[]) snatchPools;

    mapping (uint256=>Winner[]) public winners;

    mapping(address => uint256) public givers;

    mapping(address => bool) public snatchOwnerRole;

    mapping(address => mapping(uint256 => uint256)) public ticketCountMap;

    using SafeMath for uint256;

    address snatchNormalOwner;

    uint256 ticketCount=2;

    uint256[] public snatchlist;

    mapping(uint256=>SnatchInfo) public snatchInfoMap;

    mapping (address=>uint256[]) public selfSnatchInfoMap;

    struct SnatchInfo{
        address token;//
        address owner;//msg.sender
        address lastOwner;//0
        address tempOwner;//0
        uint256 amount;//0
        uint256 submitAmount;
        uint256 lastAmount;//-
        //startTime lastTime durationTime durationEndTime
        uint256[4] time;//-,-,0,-
        uint256 increaseRange;//-
        uint256 snatchCount;//0
        uint256 totalSnatchCount;//0
        uint256 totalAmount;//0
    }

    struct Winner{
        address winner;
        uint256 count;
        uint256 snatchCount;
        uint256 amount;
        uint256 winTime;
    }

    IERC1820Registry private _erc1820 = IERC1820Registry(0x88887eD889e776bCBe2f0f9932EcFaBcDfCd1820);

    // keccak256("ERC777TokensRecipient")
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor(address _nftToken) public {
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        snatchNormalOwner = msg.sender;
        ticketMap[_nftToken] = Ticket1155Nft(_nftToken);
        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    modifier onlySnatchNormalOwner(){
        require(msg.sender==snatchNormalOwner,"not owner");
        _;
    }

    function getSnatchTimeInfo(uint256 _id) view public returns(
        uint256 _startTime,uint256 _lastTime,uint256 _durationTime,
        uint256 _durationEndTime
    ){
        SnatchInfo memory snatchInfo = snatchInfoMap[_id];
        //startTime lastTime durationTime durationEndTime
        uint256[4] memory t = snatchInfo.time;
        return (t[0],t[1],t[2],t[3]);
    }

    function getSnatchBaseInfo(uint256 _id) view public returns(
        address _token,
        address _owner,address _lastOwner,address _tempOwner,
        uint256 _amount,uint256 _submitAmount,uint256 _lastAmount,
        uint256 _increaseRange,uint256 _snatchCount,
        uint256 _totalSnatchCount,uint256 _totalAmount
    ){
        SnatchInfo memory snatchInfo = snatchInfoMap[_id];
        return(snatchInfo.token,
        snatchInfo.owner,
        snatchInfo.lastOwner,
        snatchInfo.tempOwner,
        snatchInfo.amount,
        snatchInfo.submitAmount,
        snatchInfo.lastAmount,
        snatchInfo.increaseRange,
        snatchInfo.snatchCount,
        snatchInfo.totalSnatchCount,
        snatchInfo.totalAmount);
    }
    
    function getOwnerSnatch(address _owner) view public returns(uint256[] memory _ids){
        return selfSnatchInfoMap[_owner];
    }


    function addNft(address _nftToken) public onlySnatchNormalOwner(){
        ticketMap[_nftToken] = Ticket1155Nft(_nftToken);
    }

    function addSnatch(
        uint256 _tokenId,
        address nftToken,
        address token,
        uint256 submitAmount,
        uint256 durationTime,
        uint256 durationEndTime,
        uint256 increaseRange
    ) public{
        // 1155
        require(!snatchOwnerRole[msg.sender],"Has a snatch");
        require(ticketMap[nftToken].balanceOf(msg.sender,_tokenId) > 0,"not nft owner");
        IERC777 iERC777 = IERC777(token);
        uint256 cc=ticketCountMap[nftToken][_tokenId];
        require(cc<ticketCount,"Over ticket count");
        ticketCountMap[nftToken][_tokenId]=ticketCountMap[nftToken][_tokenId].add(1);
        require(iERC777.balanceOf(msg.sender) >= submitAmount,"Owner donot have enough balance");
        snatchOwnerRole[msg.sender] = false;
        uint256 id = snatchlist.length;
        snatchlist.push(id);
        uint256[4] memory time = [0,0,durationTime,durationEndTime];
        SnatchInfo memory snatchInfo = SnatchInfo(
            token,
            msg.sender,
            address(0),
            address(0),
            0,
            submitAmount,
            submitAmount,
            time,
            increaseRange,
            0,
            0,
            0
        );
        snatchInfoMap[id] = snatchInfo;
        selfSnatchInfoMap[msg.sender].push(id);
        emit AddSnatch(msg.sender,id);
    }

    function getSnatchList() view public returns(uint256[] memory){
        return snatchlist;
    }

    function snatchTokenPool(uint256 _id,uint256 _amount) public{
        SnatchInfo storage snatchInfo = snatchInfoMap[_id];
        //+1
        snatchInfo.snatchCount = snatchInfo.snatchCount.add(1);
        uint256 nowAmount = calcRangeAmount(snatchInfo.lastAmount,
                                    snatchInfo.increaseRange,
                                    snatchInfo.snatchCount);
        require(_amount >= nowAmount,"SnatchTokenPool Amount error");
        // require(snatchInfo.tempOwner!=msg.sender,"Can not repeat snatch");
        uint256 t = block.timestamp;
        uint256[4] storage time = snatchInfo.time;
        if(time[0]!=0){
            //startTime,lastTime,durationTime,durationEndTime
            require(time[1].add(time[2]) >= t, "Over duration,game over");
            require(time[0].add(time[3]) >= t, "Game is expend over time");
        }else{
            time[0] = t;
        }
        //add amount
        snatchInfo.amount = snatchInfo.amount.add(_amount);
        snatchInfo.lastOwner = snatchInfo.tempOwner;
        snatchInfo.tempOwner = msg.sender;
        snatchInfo.lastAmount = _amount;
        time[1] = t;
        snatchInfo.totalSnatchCount = snatchInfo.totalSnatchCount.add(1);
        snatchInfo.totalAmount = snatchInfo.totalAmount.add(_amount);
        safeTransferFrom(snatchInfo.token,msg.sender,address(this), _amount);
        emit SnatchTokenPool(msg.sender,_amount);
    }

    function withdrawPool(uint256 _id) public{
        SnatchInfo storage snatchInfo =snatchInfoMap[_id];
        require(snatchInfo.tempOwner == msg.sender,"Not winner");
        uint256[4] storage time = snatchInfo.time;
        require(time[1].add(time[2]) < block.timestamp
            || time[0].add(time[3]) < block.timestamp, "Game is not over");
        //10%
        uint256 reward = snatchInfo.amount;

        IERC777 iERC777 = IERC777(snatchInfo.token);
        //owner 10%
        iERC777.send(snatchInfo.owner, reward.mul(10).div(100), "");
        //50%
        iERC777.send(snatchInfo.tempOwner,reward.mul(50).div(100), "");
        emit WithdrawTokenPool(msg.sender,msg.sender,reward.mul(50).div(100));
        initStatus(_id);
    }

    function otherWithdrawToken(uint256 _id) public {
        SnatchInfo storage snatchInfo = snatchInfoMap[_id];
        uint256[4] storage time = snatchInfo.time;
        require(time[1].add(time[2]) < block.timestamp
            || time[0].add(time[3]) < block.timestamp,"Game is not over");
        uint256 reward = snatchInfo.amount;
        IERC777 iERC777 = IERC777(snatchInfo.token);
        //owner 10%
        iERC777.send(snatchInfo.owner, reward.mul(10).div(100), "");
        //win 50%
        iERC777.send(snatchInfo.tempOwner,reward.mul(45).div(100), "");
        //win 5%
        iERC777.send(msg.sender,reward.mul(5).div(100),"");
        emit WithdrawTokenPool(snatchInfo.tempOwner,msg.sender,reward.mul(45).div(100));
        initStatus(_id);
    }

    function initStatus(uint256 _id) internal{
        SnatchInfo storage snatchInfo = snatchInfoMap[_id];
        Winner memory winner = Winner(snatchInfo.tempOwner,
                        snatchInfo.snatchCount,snatchInfo.totalSnatchCount,
                        snatchInfo.amount,block.timestamp);
        winners[_id].push(winner);
        snatchInfo.lastOwner = address(0);
        snatchInfo.tempOwner = address(0);
        snatchInfo.amount = snatchInfo.amount.mul(40).div(100);
        snatchInfo.lastAmount = snatchInfo.submitAmount;
        uint256[4] storage time = snatchInfo.time;
        time[0] = 0;
        time[1] = 0;
        snatchInfo.snatchCount = 0;
    }

    function calcRangeAmount(uint256 _amount,uint256 _rate,uint256 _count) view public returns(uint256){
        return _amount.add(_amount.mul(_rate.mul(_count.div(100)).div(100)));
    }
   
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        //transfer ERC20 Token
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }

    function tokensReceived(
      address operator,
      address from,
      address to,
      uint amount,
      bytes calldata userData,
      bytes calldata operatorData
    ) external override{
        givers[from] += amount;
    }

}