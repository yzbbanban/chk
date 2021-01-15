pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SponsorWhitelistControl.sol";
import "./InviteInterface.sol";

contract Invite is InviteInterface{
    
    event Register(address owner, uint256 uid);
    
    using SafeMath for uint256;
    mapping(address => User) public userMap;
    mapping(uint256 => address) public userIdMap;
    address owner;
    User[] public users;
    struct User{
        address owner;
        uint256 id;
        address referrer;
        uint256 referrerId;
        uint256 createTime;
    }

    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );
    
    constructor(address _owner, address _first) public{
        owner = _owner;
        //init first user
        User storage firstUser = userMap[_first];
        firstUser.id = 1;
        firstUser.referrer = address(0);
        firstUser.owner = _first;
        firstUser.createTime = block.timestamp;
        //add user
        users.push(firstUser);
        userIdMap[1]=_first;

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }
    
    modifier checkOwner(){
        require(msg.sender==owner);
        _;
    }

    function getUserInfo(address _address) view public returns(address owner,
        address referrer,
        uint256 referrerId,
        uint256 id,
        uint256 createTime){
        User memory user=userMap[_address];
        return (user.owner, user.referrer,user.referrerId, user.id, user.createTime);
    }
    
    function getUserSimpleInfo(address _address) view external override returns(address referrer){
        User memory user=userMap[_address];
        return (user.referrer);
    }
 
    function getUserLength() view public returns(uint256 _userLength){
        return users.length;
    }

    function register(uint256 _referrerId) public{
        address _referrer = userIdMap[_referrerId];
        require(isUserExists(_referrer),"Referrer not exist");
        uint256 uid = users.length.add(1);
        User storage user = userMap[msg.sender];
        require(user.id == 0,"Already register");
        user.id = uid;
        user.referrer = _referrer;
        user.owner = msg.sender;
        user.createTime = block.timestamp;
        user.referrerId = _referrerId;
        //add user
        users.push(user);
        userIdMap[uid] = msg.sender;
        //add to Referrer remove to Referrer,It maybe a large storage
        // User storage userP = userMap[_referrer];
        // userP.addresses.push(msg.sender);
        // userP.inviteIds.push(uid);
        emit Register(msg.sender, uid);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (userMap[user].id != 0);
    }
 
    
}