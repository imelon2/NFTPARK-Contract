// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/IERC721Extensions.sol";

contract Ticketing is Ownable {
    error ZeroBytes();
    error ZeroAddress();
    error MinAmount();
    error UnregisteredTicket();
    error NotEnoughBalance();
    error NotSubjectToMinting();
    error DuplicateApplication();

    IERC20 public token;
    IERC721Extensions public nft;

    // title => rank => merkleRoot
    mapping (bytes32 => bytes32) public _merkleRoot;
    mapping (bytes32 => mapping(address => bool)) public isEntry;

    constructor(address _token,address _nft) {
        token = IERC20(_token);
        nft = IERC721Extensions(_nft);
    }

    event Enter(address applicant,bytes32 title);


    // 응모
    function enter(address applicant, bytes32 title) external onlyOwner {
        // 등록되지 않은 티켓에 응모할 경우
        if(nft.getProductionCost(title) == 0) { revert UnregisteredTicket(); }
        if(isEntry[title][applicant]) { revert DuplicateApplication(); }

        isEntry[title][applicant] = true;
        emit Enter(applicant, title);
    }

    function airdrop(bytes32 title, bytes32 merkleRoot) public onlyOwner {
        // 등록되지 않은 티켓이름과 등급일 경우
        if(nft.getProductionCost(title) == 0) { revert UnregisteredTicket(); }
        _merkleRoot[title] = merkleRoot;
    }

    function buyNft(bytes32 title, address buyer, string memory uri, bytes32[] calldata merkleProof) external {
        // 민팅 권한이 없는 경우
        if(!canClaim(title,buyer,merkleProof)) { revert NotSubjectToMinting(); }
        nft.safeMint(buyer,uri,title);
    }

    function canClaim(bytes32 title, address claimer, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(
                merkleProof,
                _merkleRoot[title],
                keccak256(abi.encodePacked(claimer))
            );
    }
}


// [
//   "0xcc0e3084cba5e5002886f60edc85019c6d750851b75fbf585b2986fa1868fdab",
//   "0x9697597a0c772fd7029c9ee5d825530b734c9c2c040802522a2636b1475643bc",
//   "0xe3f8767c91c0f48540c4aa0fe86519003075fae417a8ccfdeca0a1efc3ade84e",
//   "0x5743ace54a5399c3ace152e341afabcdedc094e40d24b8c9129dde34ac3ef906"
// ]


// [
//   "0x86b80f0faa1d13cde0bdf254537de93ed51afb45a18889552960e2351c68889f",
//   "0xfea5f19d21efe11fd5ca5f4abe7bd8d750a80e08885cb29fbe504f45a16b16df",
//   "0x4b24b0e3b27cfdde8f0f59345adcd6f4db2c161afbd03fc8eb66e054c5e5a911",
//   "0x01110ef548f9da492d21b2281420c6cb5c53d85094b3e569094ac743058cc379"
// ]