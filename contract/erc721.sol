// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PARK is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor() ERC721("PARK", "PARK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, msg.sender);
    }

    mapping (uint => uint) _productionCost;


    function getProductionCost(uint tokenId) public view returns(uint) {
        return _productionCost[tokenId];
    }
    //KRW
    function safeMint(address to, uint256 tokenId, string memory uri,uint256 cost)
        public
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _productionCost[tokenId] = cost;

        approvalForAllProxy(to);
    }

    function approvalForAllProxy(address holder) public onlyRole(TRANSFER_ROLE) {
        _setApprovalForAll(holder,msg.sender,true);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        delete _productionCost[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyRole(TRANSFER_ROLE) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyRole(TRANSFER_ROLE) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }
    
}

contract market {
    PARK park;

    constructor(address _park) {
        park = PARK(_park);
    }

    function listing(
        address from,
        address to,
        uint256 tokenId,
        uint _cost) public {
        
        
        uint Origin_cost = park.getProductionCost(tokenId);
        require(_cost < Origin_cost);
        if(!park.isApprovedForAll(from, address(this))) {
            park.approvalForAllProxy(from);
        }
        park.transferFrom(from, to, tokenId);
    }
}