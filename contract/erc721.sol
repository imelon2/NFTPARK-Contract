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

    mapping (bytes32 => uint) _productionCost;
    mapping (uint => bytes32) _ticketName;

    // For Business
    // Set(Create,Update,Delete) ticket Cost
    // Cost=0 => Unregistered ticket
    function setProductionCost(bytes32 name, uint256 cost) external onlyRole(MINTER_ROLE) {
        _productionCost[name] = cost;
    }

    // Get(Read) ticket Cost
    function getProductionCost(bytes32 name) public view returns(uint256) {
        return _productionCost[name];
    }

    // Getter
    function getTicketName(string memory name) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function getNFTOriginCost(uint tokenId) public view returns(uint) {
        return _productionCost[_ticketName[tokenId]];
    }


    // ERC721 Function
    function safeMint(address to, uint256 tokenId, string memory uri, bytes32 name) public onlyRole(MINTER_ROLE) {
        require(_productionCost[name] != 0,"Unregistered ticket");

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _ticketName[tokenId] = name;

        approvalForAllProxy(to,msg.sender);
    }

    function approvalForAllProxy(address holder, address operator) public onlyRole(TRANSFER_ROLE) {
        _setApprovalForAll(holder,operator,true);
    }


    // Refund function
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        delete _ticketName[tokenId];
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
        
        // 민팅되었을 때 정해진 원작 가격보다 높은 가격에 listing되면 fail
        uint original_cost = park.getNFTOriginCost(tokenId);
        require(_cost < original_cost,"The price is higher than the original price.");

        // 구매자가 구매요청 시, market contract가 transfer할 수 있게 권한 부여
        // 이미 부여된 경우, 실행 x
        if(!park.isApprovedForAll(from, address(this))) {
            park.approvalForAllProxy(from,address(this));
        }

        // park.transferFrom(from, to, tokenId);

        // 대충 listing하는 로직
    }
}