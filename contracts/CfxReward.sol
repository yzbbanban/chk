pragma solidity ^0.6.0;

import "./owner/Operator.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/IRewardNft.sol";
import "./SponsorWhitelistControl.sol";

interface CfxMiner{
    function balance() view external returns(uint256);
    function endTime() view external returns(uint256);
}

contract CfxReward is Operator{
    event ExchangeCfxReward(uint256 _tokenId, address _sender, uint256 _amount);

    using SafeMath for uint256;
    
    uint256 public rewardCfx;

    uint256 public rewardCount;

    uint256 public baseDecimal = 1e14;

    //2021-02-11 20:00:00
    // uint256 public endTime = 1613044800;

    IRewardNft iConposeNft;

    CfxMiner cfxMiner;

    mapping(uint256 => bool) public tokenHasExchange;

    // address public rewardToken;
    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor(address _iConposeNft, address _cfxMiner) public {
        iConposeNft = IRewardNft(_iConposeNft);
        cfxMiner = CfxMiner(_cfxMiner);

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    function sendCfx() payable public onlyOperator{
        require(msg.value>0,"Value wrong");
        rewardCfx = msg.value;
    }

    function sendCfx2() payable public onlyOperator{
        require(msg.value>0,"Value wrong");
    }

    function setCfxReward(uint256 _amount) public onlyOperator{
        rewardCfx = _amount;
    }

    function setBalance(uint256 _count) public onlyOperator{
        if(_count==0){
            rewardCount = cfxMiner.balance();
        }else{
            rewardCount = _count;
        }
    }


    function exchangeCfxReward(uint256 _tokenId) public{
        // iConposeNft.safeTransferFrom(msg.sender,address(1),_tokenId,1,"");
        require(block.timestamp >= cfxMiner.endTime(),"Exchange not start");
        address[] memory ow = iConposeNft.ownerOf(_tokenId);
        bool isO = false;
        for (uint256 index = 0; index < ow.length; index++) {
            if(ow[index]==msg.sender){
                isO = true;
            }
        }
        require(isO,"Not owner");
        require(!tokenHasExchange[_tokenId],"Has already exchange");
        uint256 amount = rewardCfx.div(rewardCount).div(baseDecimal).mul(baseDecimal);
        transferCfx(msg.sender,amount);
        tokenHasExchange[_tokenId] = true;
        emit ExchangeCfxReward(_tokenId, msg.sender, amount);
    }

    function getCfx(uint256 _amount) public onlyOperator{
        transferCfx(msg.sender,_amount);
    }

    function transferCfx(address _address, uint256 _value) internal{
        (bool res, ) = address(uint160(_address)).call{value:_value}("");
        require(res,"TRANSFER CFX ERROR");
    }

}