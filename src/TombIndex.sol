// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin/access/Ownable.sol";

contract TombIndex is ERC721, Ownable {
    string public baseURI;
    event baseUriUpdated(string newBaseURL);

    constructor(
        string memory _baseURI,
        address artistAddress
    ) ERC721("Tomb Series", "TOMB") {
        baseURI = _baseURI;
        _mint(artistAddress, 111);
    }


    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id));
    }

    function setBaseURI(string memory _url) public onlyOwner {
        emit baseUriUpdated(_url);
        baseURI = _url;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}
