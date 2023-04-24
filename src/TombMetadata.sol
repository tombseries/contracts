//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????:
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B ~@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7
//    Y@@@@@#                                                                ~@@@@@@ P@@@@@G
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ ~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.!B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B
//         ...........................B@@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&5JJJJJJJJJJJJJJJJJJJYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJY@@@@@@!
//    5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^

//  _____________________________________________________ Tomb Series  _____________________________________________________

//       :!JYYYYJ!.                   .JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.   7YYYYYYYYY?~.              ^JYYYYYYYYY^
//     ~&@@@@@@@@@@#7.                ?@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P  &@@@@@@@@@@@@B!           :@@@@@@@@@@@5
//    ^@@@@@@BB@@@@@@@B!              ?@@@@@&PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@@@# JGGGGGGG#@@@@@@@G^         !PGGGGGGGGG!
//    5@@@@@5  .7#@@@@@@@P^           ?@@@@@P                                .@@@@@@.         .J&@@@@@@&5:
//    Y@@@@@Y     .J&@@@@@@&5:        ?@@@@@G                                 @@@@@@.            :Y&@@@@@@&J.
//    Y@@@@@5        :5&@@@@@@&J.     ?@@@@@G                                 @@@@@@.               ^P@@@@@@@#7.
//    Y@@@@@5           ^P@@@@@@@#7.  J@@@@@G                                 @@@@@@.                  ~G@@@@@@@B!
//    Y@@@@@5              ~B@@@@@@@BG@@@@@@! PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@# JGPPPPPPPP5:        .7#@@@@@@@GPPPPPPG~
//    5@@@@@5                .7#@@@@@@@@@@&! .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G  &@@@@@@@@@@&           .J&@@@@@@@@@@@@5
//    ^5YYY5~                   .!JYYYYY7:    Y5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~.   ?5YYYYYYY5J.              :7JYYYYYYYY5^

//  ____________________________________________________ Tomb Metadata _____________________________________________________

// ________________________________________________ Deployed by TERRAIN 2022 _______________________________________________

// ____________________________________________ All tombs drawn by David Rudnick ___________________________________________

// ____________________________________________ Contract architect: Luke Miles _____________________________________________

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IIndexMarker {
    function isTomb(address _tokenContract, uint256 _tokenId) external view returns (bool);
}

interface IOwnable {
    function ownerOf(uint256 _tokenID) external view returns (address);
}

import "openzeppelin/access/Ownable.sol";
import "solady/utils/Multicallable.sol";

contract TombMetadata is Ownable, Multicallable {
    address public IndexMarker;

    event EngravingSet(address indexed _tokenContract, uint256 indexed _tokenId, address author, string _engraving);
    event BootlinkSet(address indexed _tokenContract, uint256 indexed _tokenId, address author, string _bootLink);

    mapping(address => mapping(uint256 => string)) private engravings;
    mapping(address => mapping(uint256 => string)) private bootLinks;

    constructor(address _indexMarker) {
        IndexMarker = _indexMarker;
    }

    modifier onlyTomb(address _tokenContract, uint256 _tokenId) {
        require(IIndexMarker(IndexMarker).isTomb(_tokenContract, _tokenId), "TombMetadata: Not a tomb");
        _;
    }

    modifier onlyTombOwnerOrAdmin(address _tokenContract, uint256 _tokenId) {
        if (msg.sender == owner()) {
            _;
            return;
        }

        require(IOwnable(_tokenContract).ownerOf(_tokenId) == msg.sender, "TombMetadata: Not tomb owner");
        _;
    }

    function getEngraving(address _tokenContract, uint256 _tokenId)
        public
        view
        onlyTomb(_tokenContract, _tokenId)
        returns (string memory)
    {
        return engravings[_tokenContract][_tokenId];
    }

    function getBootLink(address _tokenContract, uint256 _tokenId)
        public
        view
        onlyTomb(_tokenContract, _tokenId)
        returns (string memory)
    {
        return bootLinks[_tokenContract][_tokenId];
    }

    function setBootlink(address _tokenContract, uint256 _tokenId, string memory _bootLink)
        public
        onlyTomb(_tokenContract, _tokenId)
        onlyTombOwnerOrAdmin(_tokenContract, _tokenId)
    {
        emit BootlinkSet(_tokenContract, _tokenId, msg.sender, _bootLink);
        bootLinks[_tokenContract][_tokenId] = _bootLink;
    }

    function setEngraving(address _tokenContract, uint256 _tokenId, string memory _engraving)
        public
        onlyTomb(_tokenContract, _tokenId)
        onlyTombOwnerOrAdmin(_tokenContract, _tokenId)
    {
        emit EngravingSet(_tokenContract, _tokenId, msg.sender, _engraving);
        engravings[_tokenContract][_tokenId] = _engraving;
    }

    function updateIndexMarker(address _indexMarker) public onlyOwner {
        IndexMarker = _indexMarker;
    }
}
