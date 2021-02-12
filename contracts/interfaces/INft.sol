pragma solidity ^0.6.0;

interface INft{
    function mint(address _to,uint256 _tokenId) external returns(uint256);
    function burn(address owner, uint256 tokenId) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}