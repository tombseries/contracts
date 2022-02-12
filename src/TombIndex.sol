// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin/access/Ownable.sol";
import "base64/base64.sol";
import "./RomanNumerals.sol";

interface IERC721OwnerOf {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract TombIndex is ERC721, Ownable, RomanNumeralSubset {
    string public imageURI;
    bool public isFrozen;

    event TombUpdated(uint256 id);
    enum House { GENESIS, LUX, X2, SHADOW, COMETS, DEVASTATORS, TERRA, RONIN }
    mapping(House => string) private houses;
    function initHouses() private {
        houses[House.GENESIS] = "GENESIS";
        houses[House.LUX] = "LUX";
        houses[House.X2] = "X2";
        houses[House.SHADOW] = "SHADOW";
        houses[House.COMETS] = "COMETS";
        houses[House.DEVASTATORS] = "DEVASTATORS";
        houses[House.TERRA] = "TERRA";
        houses[House.RONIN] = "RONIN";
    }

    struct deployment {
        bool deployed;
        address _contract;
        uint256 tokenID;
        uint8 chainID;
    }

    struct Tomb {
        bool _initialized;
        string name;
        uint256 weight;
        uint256 numberInHouse;
        House house;
        deployment deployment;
    }

    mapping(uint256 => Tomb) public tombByID;

    constructor(
        string memory _imageURI,
        address artistAddress
    ) ERC721("Tomb Series", "TOMB") {
        initHouses();
        deployRonin(artistAddress);
        imageURI = _imageURI;
    }

    function deployRonin(address artistAddress) internal onlyOwner {
        _saveTomb(111, Tomb({
            _initialized: true,
            name: "TERRAIN",
            weight: 19454274,
            numberInHouse: 10,
            house: House.RONIN,
            deployment: deployment({
                _contract: address(this),
                tokenID: 111,
                chainID: 1,
                deployed: true
            })
        }));

        _mint(artistAddress, 111);
    }

    function _saveTomb(uint256 id, Tomb memory tomb) private {
        require(id > 0 && id <= 177, "Tomb out of bounds");
        tombByID[id] = tomb;
        emit TombUpdated(id);
    }

    function saveTombs(uint256[] calldata ids, Tomb[] calldata tombs) public onlyOwner {
        require(!isFrozen, "Contract is frozen");
        require(ids.length == tombs.length, "invalid input");
        for (uint256 i = 0; i < tombs.length; i++) {
            _saveTomb(ids[i], tombs[i]);   
        }
    }

    function setImageURI(string memory _url) public onlyOwner {
        require(!isFrozen, "Contract is frozen");
        imageURI = _url;
    }

    function freezeContract() public onlyOwner {
        isFrozen = true;
    }

    function tombName(uint256 id, Tomb memory tomb) private view returns (string memory) {
        return string(abi.encodePacked("Tomb ", numeral(id), unicode' – ', tomb.name));
    }

    function ordinalString(uint256 number) internal pure returns (string memory) {
        if (number <= 0) {
            return "0";
        }

        string memory suffix = "th";
        uint256 j = number % 10;
        uint256 k = number % 100;

        if (j == 1 && k != 11) {
            suffix = "st";
        } else if (j == 2 && k != 12) {
            suffix = "nd";
        } else if (j == 3 && k != 13) {
            suffix = "rd";
        }

        return string(abi.encodePacked(u256toString(number), suffix));
    }

    // TERRAIN is the 111th Tomb in the Tomb Series. It is the 10th tomb in the RONIN house, at a weight of 22.862.184.
    function tombDescription(uint256 id, Tomb memory tomb) private view returns (string memory) {
        return string(abi.encodePacked(tomb.name, " is the ", ordinalString(id), " Tomb in the Tomb Series. It is the ", ordinalString(tomb.numberInHouse), " Tomb in the ",
            houses[tomb.house], " house, at a weight of ", periodSeparatedNum(tomb.weight), "."));
    }

    function getTombOwner(uint256 id) public view returns (address) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        require(tomb.deployment.chainID == 1, "Can only check ownership value for Ethereum mainnet based Tombs");
        return IERC721OwnerOf(tomb.deployment._contract).ownerOf(tomb.deployment.tokenID);
    }

    function makeAttribute(string memory name, string memory value, bool isJSONString) private pure returns (string memory) {
        string memory strDelimiter = '';
        if (isJSONString) {
            strDelimiter = '"';
        }

        return string(abi.encodePacked(
            '{"trait_type":"', name, '","value":', strDelimiter, value, strDelimiter, '}'
        ));
    }

    function jsonForTomb(uint256 id) public view returns (bytes memory) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        return abi.encodePacked('{"name":"',tombName(id, tomb),
                '","description":"', tombDescription(id, tomb),
                '","image":"',
                imageURI, u256toString(id), '.png","attributes":[', 
                makeAttribute('House', houses[tomb.house], true), ',',
                makeAttribute('Weight', u256toString(tomb.weight), false), ',',
                makeAttribute('Number in house', u256toString(tomb.numberInHouse), false),
              ']}');
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

    function concatDotParts(string memory base, uint256 part, bool needsDot) internal pure returns (string memory) {  
        string memory glue = ".";
        if (!needsDot) {
            glue = "";
        }

        return string(abi.encodePacked(u256toString(part), glue, base));
    }

    function periodSeparatedNum(uint256 value) internal pure returns (string memory) {
        string memory result = "";
        uint128 index;
        while(value > 0) {
            uint256 part = value % 10;
            bool needsDot = index != 0 && index % 3 == 0;

            result = concatDotParts(result, part, needsDot);
            value = value / 10;
            index += 1;
        }
 
        return result;
    }

    function u256toString(uint256 value) internal pure returns (string memory) {
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
