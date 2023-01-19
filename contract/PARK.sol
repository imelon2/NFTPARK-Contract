// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interface/IERC20Extensions.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PARK is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant REFUND_ROLE = keccak256("REFUND_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token) initializer public {
        __ERC721_init("PARK", "PARK");
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(REFUND_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        token = IERC20Extensions(_token);
    }

    error ZeroBytes();
    error ZeroAddress();
    error MinAmount();
    error UnregisteredTicket();
    error NotEnoughBalance();

    
    IERC20Extensions public token;

    mapping (bytes32 => uint256) _productionCost;
    mapping (uint256 => bytes32) _title;
    mapping (bytes32 => uint) _snapshot;

    function registerTicket(bytes32 title,uint256 cost) external onlyRole(MANAGER_ROLE) {
        _productionCost[title] = cost;
        _snapshot[title] = block.number;
    }

    // Get(Read) ticket Cost
    function getProductionCost(bytes32 title) public view returns(uint256) {
        return _productionCost[title];
    }

    function getSnapshot(bytes32 title) public view returns(uint256) {
        return _snapshot[title];
    }
    
    function getOriginCost(uint tokenId) public view returns(uint) {
        return _productionCost[_title[tokenId]];
    }

    // Getter
    function getString(string memory title) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(title));
    }

    function approvalForAllProxy(address holder, address operator) public onlyRole(TRANSFER_ROLE) {
        _setApprovalForAll(holder,operator,true);
    }

    function safeMint(address to, string memory uri,bytes32 title) public onlyRole(MINTER_ROLE) {
        uint origin_cost = getProductionCost(title);
        // 등록되지 않은 티켓 민팅할 경우
        if(origin_cost == 0) {revert UnregisteredTicket();}
        // 티켓 가격보다 토큰이 없을 경우
        if(token.balanceOf(to) < origin_cost) {revert NotEnoughBalance();}

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        _title[tokenId] = title;
        // 구매 후, 토큰 소각
        token.burnFrom(to,origin_cost);
    }

    function burn(uint256 tokenId) public override virtual onlyRole(REFUND_ROLE) {
        _burn(tokenId);
        delete _title[tokenId];
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

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
