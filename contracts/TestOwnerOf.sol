pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TestOwnerOf{

    using SafeMath for uint256;

    mapping(uint256 => address[]) public ownerOfAddress;

    function ownerOf(uint256 _id) view public returns(address[] memory){
        return ownerOfAddress[_id];
    }

     function calcRangeAmount(uint256 _amount,uint256 _rate,uint256 _count,uint256 _sCount) pure public returns(uint256){
        return _amount.add(_amount.mul(_rate.mul(_count.div(_sCount))).div(100));
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) public {
        address[] storage addr = ownerOfAddress[tokenId];
        if(addr.length>0){
            addr.pop();
        }
        addr.push(to);
    }   

    function box(uint256 _m) pure public returns(uint256){
        uint256 price = 25e18;
        uint256 value = 0;
        for (uint256 index = 0; index < _m; index++) {
            value = value.add(price.mul(40).div(100).div(_m.add(index))); 
        }
        return value;
    }
}