// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extensions is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function approvalProxy(address holder, address operator) external;
}