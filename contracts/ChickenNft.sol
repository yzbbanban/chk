pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./StringUtils.sol";

contract ChickenNft is ERC721{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tokenURI;

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

    constructor() public ERC721("CHK11 token", "CHK11") {
        owner=msg.sender;
    }

    function addMiner(address _miner) public onlyOwner(){
        miners[_miner] = true;
    }

    function removeMiner(address _miner) public onlyOwner(){
        miners[_miner] = false;
    }

    function setBaseURI(string memory _tokenURI) public onlyOwner(){
        tokenURI = _tokenURI;
    }

    function awardItem(address player)
        public  onlyMiner()
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, StringUtils.strConcat(tokenURI, StringUtils.uint2str(newItemId), ".json"));

        return newItemId;
    }

}