pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Snatch{

    event SnatchPool(address _addr,uint256 _amount);
    event WithdrawPool(address _owner, address _addr,uint256 _amount);

    address[] public winnerAddresses;

    using SafeMath for uint256;

    address snatchOwner;

    uint256 public durationEndTime = 7*86400;

    uint256 public durationTime = 5*3600;

    uint256 public totalAmount;

    uint256 public snatchCount;

    uint256 public totalSnatchCount;

    uint256 public increaseRange = 20;

    address public platformAddress;

    uint256 public platformRate=10;
    uint256 public helperRate=5;

    Winner[] public winners;

    mapping(address => Winner[]) public winnerMap;

    SnatchInfo snatchInfo;

    struct SnatchInfo{
        address lastOwner;
        address tempOwner;
        uint256 amount;
        uint256 submitAmount;
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

    constructor() public{
        snatchOwner = msg.sender;
        platformAddress = msg.sender;
        snatchInfo = SnatchInfo(address(0),address(0),0,1e18,0,0,0);
    }

    modifier onlyOwner(){
        require(msg.sender==snatchOwner,"not owner");
        _;
    }

    function getCurrentSnatchInfo() view public returns(address lastOwner,
        address tempOwner,
        uint256 amount,
        uint256 submitAmount,
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
            snatchInfo.amount,snatchInfo.submitAmount,snatchInfo.lastAmount,
            snatchInfo.lastTime,snatchInfo.startTime,
            durationEndTime,durationTime,increaseRange,totalAmount,snatchCount,totalSnatchCount
            );
    }

    function getWinnerAddresses() view public returns(address[] memory _winners){
        return winnerAddresses;
    }

    function setPlatform(address _platform) public onlyOwner(){
        platformAddress = _platform;
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

    function snatchPool() payable public{
        require(msg.value >= 1 ether,"Min amount must greate than 1");
        //get now
        uint256 t = block.timestamp;
        if(snatchInfo.startTime!=0){
            require(snatchInfo.lastTime.add(durationTime) >= t, "Over duration,game over");
            require(snatchInfo.startTime.add(durationEndTime) >= t, "Game is expend over time");
        }else{
            //set time like
            snatchInfo.startTime = t;
        }
        require(snatchInfo.tempOwner!=msg.sender,"Can not repeat snatch");
        require(msg.value >= snatchInfo.lastAmount, "Amount error");
        uint256 rangeAmount = increaseRange.mul(msg.value).div(100).add(msg.value);
        require(msg.value <= rangeAmount, "Amount can not over max amount");
        // add count
        snatchCount = snatchCount.add(1);
        uint256 reward = 0;
        //todo
        if(snatchCount == 5){
            //send 5%
            reward = snatchInfo.amount;
            transferEth(platformAddress, reward.mul(5).div(100),"Transfer snatch error");
        }
        addSnatchTotalCount();
        addSnatchTotalAmount(msg.value);
        //add amount
        snatchInfo.amount = snatchInfo.amount.add(msg.value).sub(reward);
        snatchInfo.lastOwner = snatchInfo.tempOwner;
        snatchInfo.tempOwner = msg.sender;
        snatchInfo.lastAmount = msg.value;
        snatchInfo.lastTime = t;
        emit SnatchPool(msg.sender,msg.value);
    }

    function withdrawPool() public{
        require(snatchInfo.tempOwner == msg.sender,"Not winner");
        require(snatchInfo.lastTime.add(durationTime) < block.timestamp
            || snatchInfo.startTime.add(durationEndTime) < block.timestamp,"Game is not over");
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
                            reward.sub(reward.mul(48).div(100)));
        initStatus();
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
        snatchInfo.lastAmount = 1e18;
        snatchInfo.lastTime = 0;
        snatchInfo.startTime = 0;
        snatchCount = 0;
    }
   

    function transferEth(address _address, uint256 _value,string memory message) internal{
        (bool res, ) = address(uint160(_address)).call{value:_value}("");
        require(res,message);
    }

}