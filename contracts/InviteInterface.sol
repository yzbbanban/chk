pragma solidity >=0.6.0 <0.8.0;

interface InviteInterface{
    function getUserSimpleInfo(address _address) view external returns(address referrer);
}
