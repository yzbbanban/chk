pragma solidity ^0.6.0;

import "./owner/Operator.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/INft.sol";
import "./interfaces/IRewardNft.sol";
import "./SponsorWhitelistControl.sol";


contract CfxMiner is Operator{

    event ExchangeWithWord(address _sender, uint256 _tokenId, uint256 _level);
    event ExchangeRewardCard(address _sender, uint256 _tokenId);

    using SafeMath for uint256;
    //1. 猜数字可以获取一张，每天每个地址可以领取5次，每天发放 150 个
    // 2. 10号8点开奖，5日上线 总共 5*150=750
    // 3. 数量：
    //      a. C：100，O：200，N：100，F：100，L：100，U：50，X：100
    //      b. 每天随机发放150个
    // 4. 集齐之后可以合成一张 CONFLUX 卡片，凭此卡片可以兑奖，兑换完的卡片，全部销毁（字母卡片）
    // 5. 卡片可以自由交易，转移

    uint256 randNonce = 0;

    uint256 one = 1;

    INft iNft;
    IRewardNft iConposeNft;

    uint256 public constant dayCount = 150;
    mapping(address => mapping(uint256 => bool)) public isReset;
    uint256 public dayCountRest = 150;
    uint256 public lastExchangeTime;
    uint256 public balance;
    uint256 public rewardCfx;

    uint256 public constant totalCount = 750;
    uint256 public totalCountRest = 750;
    uint256[] public tokenIds;
    mapping(uint256 => uint256) tokensIndex;

    mapping (uint256 => uint) public levels;

    //2021-02-11 20:00:00
    uint256 public endTime = 1613044800;
    //2021-02-7 12:00:00
    uint256 public startTime = 1612670400;

    uint256 public minNum;
    uint256 public maxNum;

    bool public bool1;
    bool public bool2;
    bool public bool3;
    bool public bool4;

    uint256 public limitCount = 5;
    mapping(address => uint256) public addressCount;
    uint256 public period=1;
    uint256 public duration = 86400;

    mapping(uint256 => bool) public tokenHasExchange;

    // address public rewardToken;
    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor(address _iNft, address _iConposeNft) public {
        iNft = INft(_iNft);
        iConposeNft = IRewardNft(_iConposeNft);
        // rewardToken = _fc;
        minNum = 1;
        maxNum = 10;
        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    function setStartTime(uint256 _startTime, uint256 _endTime) public onlyOperator(){
        startTime = _startTime;
        endTime = _endTime;
    }

    function getBaseInfo(address _sender) view public returns(
        uint256 _minNum,
        uint256 _maxNum,
        uint256 _dayCountRest,
        uint256 _totalCountRest,
        uint256 _addressCount
        ){
        return (minNum,maxNum,dayCountRest,totalCountRest,addressCount[_sender]);
    }

    function initTotalCount1() public onlyOperator(){
        require(!bool1,"Bool1 has init");
        for (uint256 index = 0; index < 200; index++) {
            tokensIndex[index] = index;
            tokenIds.push(index);
        }
        bool1 = true;
    }

    function initTotalCount2() public onlyOperator(){
        require(bool1,"Bool1 has not init");
        require(!bool2,"Bool2 has init");
        for (uint256 index = 200; index < 400; index++) {
            tokensIndex[index] = index;
            tokenIds.push(index);
        }
        bool2 = true;
    }

    function initTotalCount3() public onlyOperator(){
        require(bool2,"Bool2 has not init");
        require(!bool3,"Bool3 has init");
        for (uint256 index = 400; index < 600; index++) {
            tokensIndex[index] = index;
            tokenIds.push(index);
        }
        bool3 = true;
    }

    function initTotalCount4() public onlyOperator(){
        require(bool3,"Bool3 has not init");
        require(!bool4,"Bool4 has init");
        for (uint256 index = 600; index < 750; index++) {
            tokensIndex[index] = index;
            tokenIds.push(index);
        }
        bool4 = true ;
    }

    function setNumber(uint256 _minNum,uint256 _maxNum) public onlyOperator(){
        if(_minNum > 0){
            minNum = _minNum;
        }
        if(_maxNum > 0){
            maxNum = _maxNum;
        }
    }

    function updateDayCount() public onlyOperator(){
        uint256 nowTime = one.mul(block.timestamp);
        dayCountRest = dayCount;
        require(startTime.add(period.mul(duration)) <= nowTime,"Not on next period");
        period = period.add(1);
        lastExchangeTime = nowTime.add(1);
    }

    function getTokenIds() view public returns(uint256[] memory _tokenIds){
        return tokenIds;
    }

    function setDuration(uint _duration) public onlyOperator(){
        duration = _duration;
    }

    function getWord() internal returns(uint256){
        uint256 limitC = addressCount[msg.sender];
        //已更新
        //1612526400 + 2 * 600
        if(startTime.add(period.mul(duration)) > block.timestamp){
            if(!isReset[msg.sender][lastExchangeTime]){
                //重置
                if(limitC!=0){
                    addressCount[msg.sender] = 0;
                }
                isReset[msg.sender][lastExchangeTime] = true;
            }
        }else{
            require(limitC < 5,"On limit");
        }

        // 生成一个1到10的随机数:
        //uint256(keccak256(abi.encode(now, msg.sender, randomIndex))) 
        uint256 random1 = uint256(keccak256(abi.encode(block.timestamp, msg.sender, randNonce))) % maxNum;
        randNonce = randNonce.add(120);
        uint256 random2 = uint256(keccak256(abi.encode(block.timestamp, msg.sender, randNonce))) % maxNum;
        uint256 guess= Math.min(random1,random2);
        return guess.add(minNum);
    }
    
    // function testExchange(uint256 tokenId) public returns(uint256 _tokenId){
    //     require(block.timestamp <= endTime,"Exchange over");
    //     require(dayCountRest > 0,"Today,sell out");
    //     require(totalCountRest > 0,"All,sell out");
    //     //随机
    //     iNft.mint(msg.sender,tokenId);
    //     _removeTokenFromRange(tokenId);
    //     //add attribute
    //     uint256 _level = checkAttribute(tokenId);
    //     levels[tokenId] = _level;
    //     dayCountRest = dayCountRest.sub(1);
    //     totalCountRest = totalCountRest.sub(1);
    //     return tokenId;
    // }


    function exchangeWithWord(uint256 _word) public returns(uint256 _tokenId){
        uint256 word = getWord();
        addressCount[msg.sender] = addressCount[msg.sender].add(1);
        if(word!=_word){
            emit ExchangeWithWord(msg.sender, word.add(10000000000),0);
            return word.add(10000000000);
        }
        require(block.timestamp <= endTime,"Exchange over");
        require(dayCountRest > 0,"Today,sell out");
        require(totalCountRest > 0,"All,sell out");
        //随机
        uint256 index = uint256(keccak256(abi.encode(block.timestamp, 
                            msg.sender, randNonce))) % totalCountRest;
        uint256 tokenId = tokenIds[index];
        iNft.mint(msg.sender,tokenId);
        _removeTokenFromRange(tokenId);
        //add attribute
        uint256 _level = checkAttribute(tokenId);
        levels[tokenId] = _level;
        dayCountRest = dayCountRest.sub(1);
        totalCountRest = totalCountRest.sub(1);
        emit ExchangeWithWord(msg.sender, tokenId,_level);
        return tokenId;
    }

    function exchangeRewardCard(uint256[] memory tokenIds) public returns(uint256 _tokenId){
        require(tokenIds.length==7,"Count error");
        //verify
        uint256 levelCount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            levelCount = levelCount.add(levels[tokenIds[i]].mul(levels[tokenIds[i]]));
        }
        require(levelCount==140,"Card error");
        for (uint256 j = 0; j < tokenIds.length; j++) {
            iNft.safeTransferFrom(msg.sender,address(1),tokenIds[j],1,"");
        }
        uint256 tokenId = iConposeNft.mint(msg.sender);
        balance = balance.add(1);
        emit ExchangeRewardCard(msg.sender, tokenId);
        return tokenId;
    }

    // function testRewardCard(uint256[] memory tokenIds) public returns(uint256 _tokenId){
    //     // for (uint256 j = 0; j < tokenIds.length; j++) {
    //     //     iNft.safeTransferFrom(msg.sender,address(1),tokenIds[j],1,"");
    //     // } 
    //     uint256 tokenId = iConposeNft.mint(msg.sender);
    //     balance = balance.add(1);
    //     emit ExchangeRewardCard(msg.sender, tokenId);
    //     return tokenId;
    // }

    function sendCfx() payable public onlyOperator{
        require(msg.value>0,"Value wrong");
        rewardCfx = rewardCfx.add(msg.value);
    }

    // function exchangeReward(uint256 _tokenId) public{
    //     iConposeNft.safeTransferFrom(msg.sender,address(0),_tokenId,1,"");
    //     IERC777 iERC777 = IERC777(rewardToken);
    //     uint256 rest777 = iERC777.balanceOf(address(this));
    //     iERC777.send(msg.sender, rest777.div(balance), "");
    // }

    function exchangeCfxReward(uint256 _tokenId) public{
        // iConposeNft.safeTransferFrom(msg.sender,address(1),_tokenId,1,"");
        require(block.timestamp >= endTime,"Exchange not start");
        address[] memory ow = iConposeNft.ownerOf(_tokenId);
        bool isO = false;
        for (uint256 index = 0; index < ow.length; index++) {
            if(ow[index]==msg.sender){
                isO = true;
            }
        }
        require(isO,"Not owner");
        require(!tokenHasExchange[_tokenId],"Has already exchange");
        transferEth(msg.sender,rewardCfx.div(balance));
    }

    function checkAttribute(uint256 random1) internal returns(uint256){
        //C：100，O：200，N：100，F：100，L：100，U：50，X：100
        //0~100,100~300,300~400,400~500,500~600,600~650,650~750
        if(random1>=0 && random1<100){
            return 1;
        }else if (random1>=100 && random1<300){
            return 2;
        }else if (random1>=300 && random1<400){
            return 3;
        }else if (random1>=400 && random1<500){
            return 4;
        }else if (random1>=500 && random1<600){
            return 5;
        }else if (random1>=600 && random1<650){
            return 6;
        }else if (random1>=650 && random1<750){
            return 7;
        }
    }

    function _removeTokenFromRange(uint256 tokenId) private {
        //最后一个
        uint256 lastTokenIndex = tokenIds.length.sub(1);
        //tokenId的位置
        uint256 tokenIndex = tokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            //最后一个token
            uint256 lastTokenId = tokenIds[lastTokenIndex];
            tokenIds[tokenIndex] = lastTokenId; 
            tokensIndex[lastTokenId] = tokenIndex;
        }

        tokenIds.pop();
    }

    function transferEth(address _address, uint256 _value) internal{
        (bool res, ) = address(uint160(_address)).call{value:_value}("");
        require(res,"TRANSFER ETH ERROR");
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

    receive() external payable {}
}