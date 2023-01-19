// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract test {
    bytes32 public a;
    string public b;

    function setBytes32(bytes32 _a) public {
        a = _a;
    }

    function setString(string calldata _b) public {
        b = _b;
    }

    function getString(string memory name) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(name));
    }
}

