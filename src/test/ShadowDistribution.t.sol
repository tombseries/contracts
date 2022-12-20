// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../ShadowNFT.sol";
import {Vm} from "forge-std/Vm.sol";
import {Utilities} from "./utils/Utilities.sol";

import {console} from "./utils/Console.sol";

import "../ShadowDistribution.sol";
import "base64/base64.sol";

contract ShadowDistributionTest is DSTest {
    Shadow internal ShadowContract;
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    ShadowDistribution internal ShadowDistributionContract;
    address internal TombCouncil = 0xcC1775Ea6D7F62b4DCA8FAF075F864d3e15Dd0F0;
    address internal Worm = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    Utilities internal utils = new Utilities();
    address internal relayer;
    address internal unauthorizedUser;
    address internal otherWallet = 0xb18989f87630b57B45d8820558ed6583d62Cb9e7;

    function setUp() public {
        relayer = utils.createUsers(1)[0];
        unauthorizedUser = utils.createUsers(1)[0];

        ShadowContract = new Shadow(TombCouncil);
        ShadowDistributionContract = new ShadowDistribution(address(ShadowContract), TombCouncil);

        vm.prank(TombCouncil, TombCouncil);
        ShadowContract.init();
        ShadowContract.setApprovalForAll(address(ShadowDistributionContract), true);

        vm.prank(ShadowDistributionContract.owner(), ShadowDistributionContract.owner());
        uint256[] memory ids = new uint256[](1);
        address[] memory addrs = new address[](1);

        ids[0] = 4;
        addrs[0] = Worm;

        ShadowDistributionContract.saveMapping(ids, addrs);

        vm.prank(TombCouncil, TombCouncil);
        ShadowContract.setApprovalForAll(address(ShadowDistributionContract), true);
    }

    function testClaim() public {
        vm.prank(relayer, relayer);

        assertEq(ShadowContract.ownerOf(4), TombCouncil, "owner should be council");
        ShadowDistributionContract.claimNFT(
            4,
            Worm,
            Worm,
            hex"21bdc3e08df19e2f747c2268e853faf9871263f5fa06719efa3831b014a7c38958da6a6bb929e74919e58a69f3167323db748c3b5abb94efb79f838da73c3cdc1c"
        );
        assertEq(ShadowContract.ownerOf(4), Worm);
    }

    function testFailClaimTwice() public {
        vm.prank(relayer, relayer);

        assertEq(ShadowContract.ownerOf(4), TombCouncil, "owner should be council");
        ShadowDistributionContract.claimNFT(
            4,
            Worm,
            Worm,
            hex"21bdc3e08df19e2f747c2268e853faf9871263f5fa06719efa3831b014a7c38958da6a6bb929e74919e58a69f3167323db748c3b5abb94efb79f838da73c3cdc1c"
        );
        assertEq(ShadowContract.ownerOf(4), Worm);
        ShadowDistributionContract.claimNFT(
            4,
            Worm,
            Worm,
            hex"21bdc3e08df19e2f747c2268e853faf9871263f5fa06719efa3831b014a7c38958da6a6bb929e74919e58a69f3167323db748c3b5abb94efb79f838da73c3cdc1c"
        );
    }

    function testFailDifferentWallet() public {
        vm.prank(relayer, relayer);

        assertEq(ShadowContract.ownerOf(4), TombCouncil, "owner should be council");
        ShadowDistributionContract.claimNFT(
            4,
            Worm,
            unauthorizedUser,
            hex"21bdc3e08df19e2f747c2268e853faf9871263f5fa06719efa3831b014a7c38958da6a6bb929e74919e58a69f3167323db748c3b5abb94efb79f838da73c3cdc1c"
        );
        assertEq(ShadowContract.ownerOf(4), Worm);
    }

    function testOtherWallet() public {
        vm.prank(relayer, relayer);

        assertEq(ShadowContract.ownerOf(4), TombCouncil, "owner should be council");
        ShadowDistributionContract.claimNFT(
            4,
            Worm,
            otherWallet,
            hex"6ca05722ee848ce7815fd08897ac35de44523f95b17f4235522a1e88981378250f109342db0bd113e520ca40449dcc0079de43d9b7bef590d74189a1a713988c1c"
        );
        assertEq(ShadowContract.ownerOf(4), otherWallet);
    }
}
