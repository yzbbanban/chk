pragma solidity ^0.6.0;

interface IRewardNft{
    function mint(address _to) external returns(uint256);
    function burn(address owner, uint256 tokenId) external;
    function ownerOf(uint256 _id) view external returns(address[] memory);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}