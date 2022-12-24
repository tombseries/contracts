// File: contracts/Shadow.sol

pragma solidity ^0.8.0;

import "solmate/tokens/ERC721.sol";
import "openzeppelin/access/Ownable.sol";

// used for testing shadow beacon on goerli
contract ShadowBeaconDummy is ERC721, Ownable {
    constructor() public ERC721("House SHADOW TEST", "SHD") {
        for (uint256 i = 1; i <= 36; i++) {
            _mint(msg.sender, i);
        }
    }

    function tokenURI(uint256 tokenID) public pure override returns (string memory) {
        return "";
    }
}
