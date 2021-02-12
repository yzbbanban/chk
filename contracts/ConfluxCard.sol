
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./SponsorWhitelistControl.sol";

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

//   function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
//     return strConcat(_a, _b, _c, _d, "");
//   }

  function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
    return strConcat(_a, _b, "", "", "");
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
      bstr[k--] = byte(uint8(48 + _i % 10));
      _i /= 10;
    }
    return string(bstr);
  }

  function fromAddress(address addr) internal pure returns(string memory) {
    bytes20 addrBytes = bytes20(addr);
    bytes16 hexAlphabet = "0123456789abcdef";
    bytes memory result = new bytes(42);
    result[0] = '0';
    result[1] = 'x';
    for (uint i = 0; i < 20; i++) {
      result[i * 2 + 2] = hexAlphabet[uint8(addrBytes[i] >> 4)];
      result[i * 2 + 3] = hexAlphabet[uint8(addrBytes[i] & 0x0f)];
    }
    return string(result);
  }
}

contract ConfluxCard is ERC1155 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address owner;
    // Contract name
    string public name="Conflux Card";
    // Contract symbol
    string public symbol="CFX CARD";

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    string baseUri;

    mapping(address => bool) public miners;

    mapping(uint256 => address[]) public ownerOfAddress;

    modifier onlyOwner(){
        require(owner==msg.sender,"Not owner");
        _;
    }

    modifier onlyMiner(){
        require(miners[msg.sender],"Not miner");
        _;
    }

    SponsorWhitelistControl public constant SPONSOR = SponsorWhitelistControl(
        address(0x0888000000000000000000000000000000000001)
    );

    constructor() public ERC1155("http://nft.yzbbanban.com:18756/v1/nft/conflux/") {
        owner=msg.sender;
        baseUri = "http://nft.yzbbanban.com:18756/v1/nft/conflux/";

        // register all users as sponsees
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

    function addMiner(address _miner) public onlyOwner(){
        miners[_miner] = true;
    }

    function removeMiner(address _miner) public onlyOwner(){
        miners[_miner] = false;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner(){
        super._setURI(_baseUri);
        baseUri = _baseUri;
    }

    function isTokenOwner(address _owner,uint256 _id) view public returns(bool){
        return balanceOf(_owner,_id)>0;
    }

    function ownerOf(uint256 _id) view public returns(address[] memory){
        return ownerOfAddress[_id];
    }

    function tokensOf(address _owner) view public returns(uint256[] memory _tokens){
        return _ownedTokens[_owner];
    }

    function uri(uint256 _id) external view override returns (string memory) {
        return Strings.strConcat(baseUri, Strings.uint2str(_id), ".json");
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override{
        super.safeTransferFrom(from,to,tokenId,amount,data);
         _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        super.safeBatchTransferFrom(from,to,ids,amounts,data);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 tokenId = ids[i];
            uint256 amount = amounts[i];

            _removeTokenFromOwnerEnumeration(from, tokenId);
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        address[] storage addr = ownerOfAddress[tokenId];
        if(addr.length>0){
            addr.pop();
        }
        addr.push(to);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function mint(address _to,uint256 tokenId) public onlyMiner() returns(uint256){
        // _tokenIds.increment();
        // uint256 newItemId = _tokenIds.current();
        _mint(_to, tokenId, 1, bytes(Strings.strConcat(baseUri, Strings.fromAddress(address(this)), "/"))); 
        _addTokenToAllTokensEnumeration(tokenId);
        _addTokenToOwnerEnumeration(_to, tokenId);
        return tokenId;
    }

     /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function burn(address owner, uint256 tokenId) public {
        super._burn(owner, tokenId,1);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].pop();

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

     /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }
}