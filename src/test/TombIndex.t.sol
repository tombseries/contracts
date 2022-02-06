// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../TombIndex.sol";
import "base64/base64.sol";

interface CheatCodes {
  function prank(address) external;
  function ffi(string[] calldata) external returns (bytes memory);
}


contract TombContractTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    address ArtistAddress = 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46;
    TombIndex internal TombContract;

    function setUp() public {
        cheats.prank(ArtistAddress);
        TombContract = new TombIndex("https://tombseri.es/img/", ArtistAddress);
    }

    function testOwnerOf() public {
        assertEq(TombContract.ownerOf(111), ArtistAddress);
    }

    function testSetURI() public {
        cheats.prank(ArtistAddress);
        TombContract.setImageURI("test");
    }

    function testFailUseOwnerFunction() public {
        cheats.prank(0xfB843f8c4992EfDb6b42349C35f025ca55742D33);
        TombContract.setImageURI("test");
    }

    function testFailDoesntExit() public {
        emit log(TombContract.tokenURI(178));
    }

    function testTerrainTokenURI() public {
        string memory uri = TombContract.tokenURI(111);
        emit log(string(uri));
    }
}
