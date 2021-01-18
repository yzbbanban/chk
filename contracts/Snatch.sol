pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SponsorWhitelistControl.sol";
import "./InviteInterface.sol";

contract Snatch{

    event SnatchPool(address _addr,uint256 _amount);
    event WithdrawPool(address _owner, address _addr,uint256 _amount);

    address[] public winnerAddresses;

    using SafeMath for uint256;

    address snatchOwner;

    uint256 public durationEndTime = 5*86400;

    uint256 public durationTime = 1*3600;

    uint256 public surprise = 100;

    uint256 public totalAmount;

    uint256 public snatchCount;

    uint256 public totalSnatchCount;

    uint256 public invitePercent = 10;

    uint256 public increaseRange = 20;

    address public platformAddress;

    uint256 public submitAmount = 10e18;

    uint256 public platformRate = 20;
    uint256 public helperRate = 5;

    mapping(address => Reward) rewards;

    InviteInterface invite;

    Winner[] public winners;

    mapping(address => Winner[]) public winnerMap;

    SnatchInfo snatchInfo;

    struct Reward{
        address owner;
        uint256 inviteReward;
        uint256 surprise;
    }

    struct SnatchInfo{
        address lastOwner;
        address tempOwner;
        uint256 amount;
        uint256 lastAmount;
        uint256 lastTime;
        uint256 startTime;
    }

    struct Winner{
        address winner;
        uint256 count;
        uint256 scount;
        uint256 amount;
        uint256 winTime;
    }

    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor(InviteInterface _invite) public{
        snatchOwner = msg.sender;
        platformAddress = msg.sender;
        snatchInfo = SnatchInfo(address(0),address(0),0,submitAmount,0,0);
        invite = _invite;
        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    modifier onlyOwner(){
        require(msg.sender==snatchOwner,"not owner");
        _;
    }

    function getCurrentSnatchInfo() view public returns(
        address lastOwner,
        address tempOwner,
        uint256 amount,
        uint256 _submitAmount,
        uint256 lastAmount,
        uint256 lastTime,
        uint256 startTime,
        uint256 _durationEndTime,
        uint256 _durationTime,
        uint256 _increaseRange,
        uint256 _totalAmount,
        uint256 _snatchCount,
        uint256 _totalSnatchCount
        ){
            return (snatchInfo.lastOwner,snatchInfo.tempOwner,
            snatchInfo.amount,submitAmount,snatchInfo.lastAmount,
            snatchInfo.lastTime,snatchInfo.startTime,
            durationEndTime,durationTime,increaseRange,totalAmount,snatchCount,totalSnatchCount
            );
    }

    function getWinnerAddresses() view public returns(address[] memory _winners){
        return winnerAddresses;
    }

    function setSubmitM(uint256 _amount) public onlyOwner(){
        submitAmount = _amount;
    }

    function setInvitePercent(uint256 _invitePercent) public onlyOwner(){
        invitePercent = _invitePercent;
    }
    function setInviteInterface(InviteInterface _invite) public onlyOwner(){
        invite = _invite;
    }

    function setPlatform(address _platform) public onlyOwner(){
        platformAddress = _platform;
    }

    function setSurprise(uint256 _surprise) public onlyOwner(){
        surprise = _surprise;
    }
    
    function setDuration(uint256 _durationTime,uint256 _durationEndTime) public onlyOwner(){
        if(_durationTime!=0){
            durationTime = _durationTime;
        }
        if(_durationEndTime!=0){
            durationEndTime = _durationEndTime;
        }
    }

    function setPlatformRate(uint256 _rate,uint256 _increaseRange) public onlyOwner(){
        platformRate = _rate;
        increaseRange = _increaseRange;
    }

    function getNow() view public returns(uint256){
        return block.timestamp;
    }

    function getRewards(address _owner) view public returns(uint256 _inviteReward,uint256 _surprise){
        Reward memory re = rewards[_owner];
        return (re.inviteReward,re.surprise);
    }

    function snatchPool() payable public{
        //get now
        uint256 t = block.timestamp;
        if(snatchInfo.startTime!=0){
            require(snatchInfo.lastTime.add(durationTime) >= t, "Over duration,game over");
            require(snatchInfo.startTime.add(durationEndTime) >= t, "Game is expend over time");
        }else{
            //set time like
            snatchInfo.startTime = t;
        }
        // require(snatchInfo.tempOwner!=msg.sender,"Can not repeat snatch");
        //cal amounnt
        require(msg.value >= 10 ether,"Min amount must greate than 10");
        uint256 rangeAmount = increaseRange.mul(msg.value).div(100).add(msg.value);
        require(msg.value <= rangeAmount, "Amount can not over max amount");
        // add count
        snatchCount = snatchCount.add(1);
        //check amount
        uint256 nowAmount = calcRangeAmount(submitAmount,increaseRange,snatchCount,surprise);
        require(msg.value >= nowAmount,"Amount error");
        //发放推荐
        uint256 rest = checkInvite(msg.sender,msg.value);
        uint256 reward = 0;
        //彩蛋，单轮中会有
        if(snatchCount.div(surprise)>=1){
            //send 5%
            //保留小数4位
            uint256 rem = snatchInfo.amount.div(1e14).mul(1e14);
            reward = rem.mul(5).div(100);
            reward = snatchInfo.amount.sub(rem).add(reward);
            //发给用户
            // transferEth(msg.sender, reward,"Transfer snatch error");
            Reward storage senderReward = rewards[msg.sender];
            senderReward.surprise = senderReward.surprise.add(reward);
        }
        addSnatchTotalCount();
        addSnatchTotalAmount(msg.value);
        //add amount
        snatchInfo.amount = snatchInfo.amount.add(msg.value).sub(reward).sub(rest);
        snatchInfo.lastOwner = snatchInfo.tempOwner;
        snatchInfo.tempOwner = msg.sender;
        snatchInfo.lastAmount = msg.value;
        snatchInfo.lastTime = t;
        emit SnatchPool(msg.sender,msg.value);
    }

    function checkInvite(address _sender,uint256 _value) internal returns(uint256 _restAmount){
        address parent = invite.getUserSimpleInfo(_sender);
        uint256 am = 0;
        if(parent != address(0)){
            am = invitePercent.mul(_value).div(100);
            Reward storage rewardP = rewards[parent];
            rewardP.inviteReward = rewardP.inviteReward.add(am);
            // transferEth(parent, 
            //     am,
            //     "Transfer invite error");
        }
        //发放给推荐的钱
        return am;
    }

    function withdrawPool() public{
        require(snatchInfo.tempOwner == msg.sender,"Not winner");
        require(snatchInfo.lastTime.add(durationTime) < block.timestamp
            || snatchInfo.startTime.add(durationEndTime) < block.timestamp,"Game is not over");
        require(snatchInfo.tempOwner!=address(0),"Already withdraw");
        uint256 reward = snatchInfo.amount;
        //r*10%
        transferEth(platformAddress, reward.mul(platformRate).div(100),"Transfer platform error");
        // r-r*10%
        //50% to winner
        transferEth(snatchInfo.tempOwner,reward.mul(50).div(100),"Transfer winner error");
        //decimals
        snatchInfo.amount = reward.sub(reward.mul(platformRate).div(100))
                                        .sub(reward.mul(50).div(100));
        emit WithdrawPool(msg.sender,msg.sender,reward.sub(reward.mul(50).div(100)));
        initStatus();
    }

    function otherWithdraw() public {
        require(snatchInfo.lastTime.add(durationTime) < block.timestamp
            || snatchInfo.startTime.add(durationEndTime) < block.timestamp,"Game is not over");
        require(snatchInfo.tempOwner!=address(0),"Other already withdraw");
        uint256 reward = snatchInfo.amount;
        //platform 10%
        transferEth(platformAddress, reward.mul(platformRate).div(100),"Other transfer platform error");
        //win 45%
        transferEth(snatchInfo.tempOwner,reward.mul(45).div(100),"Other transfer winner error");
        //win 5%
        transferEth(msg.sender,reward.mul(helperRate).div(100),"Other transfer helper error");
        //40% decimals
        snatchInfo.amount = reward.sub(reward.mul(platformRate).div(100))
                                    .sub(reward.mul(45).div(100))
                                    .sub(reward.mul(helperRate).div(100));
        emit WithdrawPool(snatchInfo.tempOwner,
                            msg.sender,
                            reward.sub(reward.mul(45).div(100)));
        initStatus();
    }

    function withdrawReward(address _owner) public{
        Reward storage reward = rewards[_owner];
        uint256 r = reward.inviteReward.add(reward.surprise);
        require(r > 0,"No reward");
        reward.inviteReward = 0;
        reward.surprise = 0;
        transferEth(_owner, r, "transfer reward error");
    }

    function addSnatchTotalAmount(uint256 _amount) internal{
        totalAmount = totalAmount.add(_amount);
    }

    function addSnatchTotalCount() internal{
        totalSnatchCount = totalSnatchCount.add(1);
    }

    function initStatus() internal{
        Winner memory winner = Winner(snatchInfo.tempOwner,
                        snatchCount,totalSnatchCount,
                        snatchInfo.amount,block.timestamp);
        winnerAddresses.push(snatchInfo.tempOwner);
        winners.push(winner);
        winnerMap[snatchInfo.tempOwner].push(winner);
        snatchInfo.lastOwner = address(0);
        snatchInfo.tempOwner = address(0);
        snatchInfo.lastAmount = submitAmount;
        snatchInfo.lastTime = 0;
        snatchInfo.startTime = 0;
        snatchCount = 0;
    }
   

    function transferEth(address _address, uint256 _value,string memory message) internal{
        (bool res, ) = address(uint160(_address)).call{value:_value}("");
        require(res,message);
    }

    function calcRangeAmount(uint256 _amount,uint256 _rate,uint256 _count,uint256 _sCount) pure public returns(uint256){
        return _amount.add(_amount.mul(_rate.mul(_count.div(_sCount))).div(100));
    }

    receive() external payable {}

}