// File: contracts/Shadow.sol

pragma solidity ^0.8.0;

import "solmate/tokens/ERC721.sol";
import "openzeppelin/access/Ownable.sol";

contract Shadow is ERC721, Ownable {
    address tombCouncil;

    constructor(address _tombCouncil) public ERC721("House SHADOW", "SHD") {
        tombCouncil = _tombCouncil;
    }

    function init() public {
        require(msg.sender == tombCouncil, "Only tombCouncil can init");
        for (uint256 i = 1; i <= 36; i++) {
            _mint(tombCouncil, i);
        }
    }

    function tokenURI(uint256 tokenID) public pure override returns (string memory) {
        return "";
    }
}
