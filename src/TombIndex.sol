// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin/access/Ownable.sol";
import "base64/base64.sol";
import "./RomanNumerals.sol";

contract TombIndex is ERC721, Ownable {
    string public imageURI;
    bool public isFrozen;

    event TombUpdated(uint256 id);
    string[] private houses = ["GENESIS", "LUX", "X2", "SHADOW", "COMETS", "DEVASTATORS", "TERRA", "RONIN"];

    struct deployment {
        uint16 chainID;
        bool deployed;
        address hostContract;
        uint256 tokenID;
    }

    struct Tomb {
        bool _initialized;
        uint32 weight;
        uint8 numberInHouse;
        uint house;
        deployment deployment;
    }

    mapping(uint8 => Tomb) public tombByID;
    mapping(uint8 => string) public tombNameByID;

    constructor(
        string memory _imageURI,
        address artistAddress
    ) ERC721("Tomb Series", "TOMB") {
        _deployRonin(artistAddress);
        imageURI = _imageURI;
    }

    function freezeContract() public onlyOwner {
        isFrozen = true;
    }

    modifier notFrozen() {
        require(!isFrozen, "Contract is frozen");
        _;
    }

    function _deployRonin(address artistAddress) internal onlyOwner {
        _saveTomb(111, "TERRAIN", Tomb({
            _initialized: true,
            weight: 19454274,
            numberInHouse: 10,
            house: 7,
            deployment: deployment({
                hostContract: address(this),
                tokenID: 111,
                chainID: 1,
                deployed: true
            })
        }));

        _mint(artistAddress, 111);
    }

    function _saveTomb(uint256 id, string memory name, Tomb memory tomb) internal {
        require(id > 0 && id <= 177, "Tomb out of bounds");
        uint8 id8 = uint8(id);
        tombByID[id8] = tomb;
        tombNameByID[id8] = name;
        emit TombUpdated(id);
    }

    function saveTombs(uint256[] calldata ids, string[] calldata names, Tomb[] calldata tombs) public onlyOwner notFrozen {
        require(ids.length == tombs.length, "invalid input");
        require(names.length == tombs.length, "invalid input");
        for (uint256 i = 0; i < tombs.length; i++) {
            _saveTomb(ids[i], names[i], tombs[i]);   
        }
    }

    function setImageURI(string memory _url) public onlyOwner notFrozen {
        imageURI = _url;
    }

    function _tombName(uint8 id) internal view returns (string memory) {
        return string(abi.encodePacked("Tomb ", RomanNumeral.ofNum(id), unicode' — ', tombNameByID[id]));
    }

    function _ordinalString(uint8 number) internal pure returns (string memory) {
        if (number <= 0) {
            return "0";
        }

        string memory suffix = "th";
        uint8 j = number % 10;
        uint8 k = number % 100;

        if (j == 1 && k != 11) {
            suffix = "st";
        } else if (j == 2 && k != 12) {
            suffix = "nd";
        } else if (j == 3 && k != 13) {
            suffix = "rd";
        }

        return string(abi.encodePacked(_u256toString(number), suffix));
    }

    function _tombDescription(uint8 id, Tomb memory tomb) internal view returns (string memory) {
        return string(abi.encodePacked(tombNameByID[id], " is the ", _ordinalString(id), " Tomb in the Tomb Series. It is the ", _ordinalString(tomb.numberInHouse), " Tomb in the ",
            houses[tomb.house], " house, at a weight of ", _periodSeparatedNum(tomb.weight), "."));
    }

    function ownerOfTomb(uint8 id) public view returns (address) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        require(tomb.deployment.chainID == 1, "Can only check ownership value for Ethereum mainnet based Tombs");
        return ERC721(tomb.deployment.hostContract).ownerOf(tomb.deployment.tokenID);
    }

    function _makeAttribute(string memory name, string memory value, bool isJSONString) internal pure returns (string memory) {
        string memory strDelimiter = '';
        if (isJSONString) {
            strDelimiter = '"';
        }

        return string(abi.encodePacked(
            '{"trait_type":"', name, '","value":', strDelimiter, value, strDelimiter, '}'
        ));
    }

    function jsonForTomb(uint8 id) public view returns (bytes memory) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        return abi.encodePacked('{"name":"',_tombName(id),
                '","description":"', _tombDescription(id, tomb),
                '","image":"',
                imageURI, _u256toString(id), '.png","attributes":[', 
                _makeAttribute('House', houses[tomb.house], true), ',',
                _makeAttribute('Weight', _u256toString(tomb.weight), false), ',',
                _makeAttribute('Number in house', _u256toString(tomb.numberInHouse), false),
              ']}');
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(jsonForTomb(uint8(id)))));
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

    function _concatDotParts(string memory base, uint256 part, bool needsDot) internal pure returns (string memory) {  
        string memory glue = ".";
        if (!needsDot) {
            glue = "";
        }

        return string(abi.encodePacked(_u256toString(part), glue, base));
    }

    function _periodSeparatedNum(uint256 value) internal pure returns (string memory) {
        string memory result = "";
        uint128 index;
        while(value > 0) {
            uint256 part = value % 10;
            bool needsDot = index != 0 && index % 3 == 0;

            result = _concatDotParts(result, part, needsDot);
            value = value / 10;
            index += 1;
        }
 
        return result;
    }

    function _u256toString(uint256 value) internal pure returns (string memory) {
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
