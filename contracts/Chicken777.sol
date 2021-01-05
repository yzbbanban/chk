pragma solidity ^0.6.2;

import "../node_modules/@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract Chicken777 is ERC777 {

    address owner;

    address public minter;

    mapping(address=>bool) mainMinter;

    //---------- Minter Begin ---------//
    modifier onlyMinter() {
        require(mainMinter[msg.sender], "MinterRole: caller does not have the Minter role or above");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==owner, "Owner Role: caller does not have the Minter role or above");
        _;
    }

    constructor()
        ERC777("CKCK77 Token", "CKCK77", new address[](0))
        public
    {
        owner = msg.sender;
        _mint(msg.sender, 1000000e18, "", "");
    }

    function addMinter(address _minter) public onlyOwner(){
        mainMinter[_minter]=true;
    }

    function removeMinter(address _minter) public onlyOwner(){
        mainMinter[_minter]=false;
    }

    function addTokens(address _to, uint256 _value) external onlyMinter(){
        _mint(_to, _value, "", "");
    }
}
