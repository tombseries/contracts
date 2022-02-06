// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../TombIndex.sol";

interface CheatCodes {
  function prank(address) external;
}


contract TombContractTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    TombIndex internal TombContract;

    function setUp() public {
        cheats.prank(0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
        TombContract = new TombIndex("https://tombseri.es", 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
    }

    function testOwnerOf() public {
        assertEq(TombContract.ownerOf(111), 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
    }

    function testSetURI() public {
        cheats.prank(0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
        TombContract.setBaseURI("test");
    }

    function testFailUseOwnerFunction() public {
        cheats.prank(0xfB843f8c4992EfDb6b42349C35f025ca55742D33);
        TombContract.setBaseURI("test");
    }
}
