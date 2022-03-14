// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../TombIndex.sol";
import "../Ronin.sol";

contract RoninTest is DSTest {
    address ArtistAddress = 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46;
    address OtherAddress = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    TombIndex internal TombContract;
    Ronin internal RoninContract;

    function setUp() public {
        TombContract = new TombIndex("https://tombseri.es/img/", ArtistAddress);
        RoninContract = new Ronin(address(TombContract), 160);
    }

    function testTokenURI() public {
        bytes memory uri = TombContract.jsonForTomb(160);
        emit log(string(uri));
        assertEq(TombContract.tokenURI(160), RoninContract.tokenURI(160));
    }

    function testFailTokenURI() view public {
        RoninContract.tokenURI(1);
    }

    function testAMint() public {
        RoninContract.mint();
        assertEq(RoninContract.ownerOf(160), RoninContract.owner());
    }

    function testFailASecondMint() public {
        RoninContract.mint();
        RoninContract.mint();
    }

    function testRoyaltyInfo() public {
         (address artist, uint256 amount) = RoninContract.royaltyInfo(160, 4234000000);
         assertEq(artist, ArtistAddress);
         assertEq(amount, 423400000);
    }
}
