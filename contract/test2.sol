// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract test2 {
    uint256 public num;

    function callFunc() public view returns(uint256) {
        return num;
    }

    function callFuncWithParam(uint256 _num) public view returns(uint256) {
        return num + _num;
    }

    function sendFunc(uint256 _num) public {
        num = _num;
    }
}