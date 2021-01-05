pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Chicken20 is ERC20{

    address owner;

    mapping(address => bool) public miners;

    modifier onlyOwner(){
        require(msg.sender==owner,"Not owner");
        _;
    }

    modifier onlyMiner(){
        require(miners[msg.sender],"Not miner");
        _;
    }

    function addMiner(address _miner) public onlyOwner(){
        miners[_miner] = true;
    }

    function removeMiner(address _miner) public onlyOwner(){
        miners[_miner] = false;
    }

    constructor(uint256 _initialSupply) public ERC20("chiken111", "CHK111") {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    function addTokens(address _address,uint256 _amount) public onlyMiner(){
         _mint(_address, _amount);
    }

}