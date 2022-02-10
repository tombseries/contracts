// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "solmate/tokens/ERC721.sol";
import "../TombIndex.sol";
import "base64/base64.sol";

interface CheatCodes {
  function prank(address) external;
  function ffi(string[] calldata) external returns (bytes memory);
}

contract ExampleRonin is ERC721 {
    constructor() ERC721("Ronin", "RNIN") {
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
    
    address OtherAddress = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;

    function mint2() public {
        _mint(OtherAddress, 0);
    }

}


contract TombContractTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    ExampleRonin internal ExtNFTContract = ExampleRonin(0x517e643F53EB3622Fd2c3A12C6BFde5E7Bc8D5ca);
    address ArtistAddress = 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46;
    address OtherAddress = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    TombIndex internal TombContract;

    enum House { GENESIS, LUX, X2, SHADOW, COMETS, DEVASTATORS, TERRA, RONIN }
    struct Tomb {
        bool _active;
        string name;
        uint256 weight;
        House house;
        address deployedContract;
        uint256 deployedTokenID;
    }

    function setUp() public {
        ExtNFTContract = new ExampleRonin();
        ExtNFTContract.mint2();
        TombContract = new TombIndex("https://tombseri.es/img/", ArtistAddress);
        TombContract.saveTomb(21, TombIndex.Tomb({
            _initialized: true,
            name: "EQUINOX",
            weight: 18356125,
            numberInHouse: 10,
            house: TombIndex.House.RONIN,
            deployment: TombIndex.deployment({
                _contract: address(ExtNFTContract),
                tokenID: 0,
                chainID: 0,
                deployed: true
            })
        }));
        TombContract.transferOwnership(ArtistAddress);
    }

    function testOwnerOf() public {
        assertEq(TombContract.ownerOf(111), ArtistAddress);
    }

    function testExternalOwnerOf() public {
        assertEq(TombContract.getTombOwner(21), OtherAddress);
    }

    function testSetURI() public {
        cheats.prank(ArtistAddress);
        TombContract.setImageURI("test");
    }

    function testFailUseOwnerFunction() public {
        cheats.prank(0xfB843f8c4992EfDb6b42349C35f025ca55742D33);
        TombContract.setImageURI("test");
    }

    function testFailDoesntExist() public {
        emit log(TombContract.tokenURI(178));
    }

    function testTerrainTokenURI() public {
        bytes memory uri = TombContract.jsonForTomb(111);
        emit log(string(uri));
    }
}
