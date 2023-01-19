// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC721Extensions is IERC721 {
    function safeMint(address to, string memory uri,bytes32 title) external;
    function getProductionCost(bytes32 title) external view returns(uint256);
    function getOriginCost(uint tokenId) external  view returns(uint);
    function approvalForAllProxy(address holder, address operator) external;
}