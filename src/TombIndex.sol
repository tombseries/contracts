// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin/access/Ownable.sol";
import "base64/base64.sol";
import "./RomanNumerals.sol";

contract TombIndex is ERC721, Ownable, RomanNumeralSubset {
    string public imageURI;
    bool public isFrozen;

    event tombUpdated(uint256 id);
    enum House { GENESIS, LUX, RONIN, DEVASTATORS, COMETS, SHADOW, TERRA, X2 }
    mapping(House => string) public Houses;
    function initHouses() private {
        Houses[House.GENESIS] = "GENESIS";
        Houses[House.LUX] = "LUX";
        Houses[House.RONIN] = "RONIN";
        Houses[House.DEVASTATORS] = "DEVASTATORS";
        Houses[House.COMETS] = "COMETS";
        Houses[House.SHADOW] = "SHADOW";
        Houses[House.TERRA] = "TERRA";
        Houses[House.X2] = "X2";
    }

    struct Tomb {
        string name;
        uint256 weight;
        House house;
        address deployedContract;
        uint256 deployedTokenID;
    }

    mapping(uint256 => Tomb) public tombs;

    constructor(
        string memory _imageURI,
        address artistAddress
    ) ERC721("Tomb Series", "TOMB") {
        initHouses();
        deployRonin(artistAddress);
        imageURI = _imageURI;
    }

    function deployRonin(address artistAddress) private {
        saveTomb(111, Tomb({
            name: "TERRAIN",
            weight: 18356125,
            house: House.RONIN,
            deployedContract: address(this),
            deployedTokenID: 111
        }));

        _mint(artistAddress, 111);
    }

    function saveTomb(uint256 id, Tomb memory tomb) public onlyOwner {
        require(!isFrozen, "Contract is frozen");
        require(id > 0 && id <= 177, "Tomb out of bounds");
        tombs[id] = tomb;
    }

    function setImageURI(string memory _url) public onlyOwner {
        require(!isFrozen, "Contract is frozen");
        imageURI = _url;
    }

    function freezeContract() public onlyOwner {
        isFrozen = true;
    }

    function tombName(uint256 id, Tomb memory tomb) public view returns (string memory) {
        return string(abi.encodePacked("Tomb ", numeral(id), " - ", tomb.name));
    }

    function jsonForTomb(uint256 id) public view returns (bytes memory) {
        Tomb memory tomb = tombs[id];
        require(tomb.weight != 0, "Tomb doesn't exist");
        return abi.encodePacked('{"name":"',tombName(id, tomb),
                '","image":"',
                imageURI, toString(id),
             '.png", "attributes":[{"trait_type":"House","value":"',
                Houses[tomb.house], 
                '"},{"trait_type":"Weight","value":', toString(tomb.weight), '}]'
             , '}');
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(jsonForTomb(id))));
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


    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
