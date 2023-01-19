// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PARKt is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("NFT_PARK_TOKEN", "PARKt");
        __ERC20Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }
    error ZeroAddress();
    address public nft;

    function initNft(address _nft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nft=_nft;
    }
    
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if(nft == address(0)) {revert ZeroAddress();}
        _mint(to, amount);

        if(allowance(to,nft) == 0) {
            approvalProxy(to,nft);
        }
    }

    function approvalProxy(address holder, address operator) public onlyRole(MINTER_ROLE) {
        _approve(holder,operator,type(uint256).max);
    }

    function burnFrom(address account, uint256 amount) public virtual override onlyRole(MINTER_ROLE) {
        _burn(account, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
