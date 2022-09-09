// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../ShadowNFT.sol";
import { Vm } from "forge-std/Vm.sol";
import { Utilities } from "./utils/Utilities.sol";

import { console } from "./utils/Console.sol";

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
    ShadowDistributionContract = new ShadowDistribution(
      address(ShadowContract),
      TombCouncil
    );

    vm.prank(TombCouncil, TombCouncil);
    ShadowContract.init();
    ShadowContract.setApprovalForAll(address(ShadowDistributionContract), true);

    vm.prank(
      ShadowDistributionContract.owner(),
      ShadowDistributionContract.owner()
    );
    uint256[] memory ids = new uint256[](1);
    address[] memory addrs = new address[](1);

    ids[0] = 1;
    addrs[0] = Worm;

    ShadowDistributionContract.saveMapping(ids, addrs);

    vm.prank(TombCouncil, TombCouncil);
    ShadowContract.setApprovalForAll(address(ShadowDistributionContract), true);
  }

  function testClaim() public {
    vm.prank(relayer, relayer);

    assertEq(ShadowContract.ownerOf(1), TombCouncil, "owner should be council");
    ShadowDistributionContract.claimNFT(
      1,
      Worm,
      Worm,
      hex"ea6bad825c8a0a4a482e7ac4b3698ae3e00f16532b61b70833263d05b01382d964c18acafcbece6146f5b90fe5d1bd2b6e1f1e96fb0996d52df393f0afe535901c"
    );
    assertEq(ShadowContract.ownerOf(1), Worm);
  }

  function testFailClaimTwice() public {
    vm.prank(relayer, relayer);

    assertEq(ShadowContract.ownerOf(1), TombCouncil, "owner should be council");
    ShadowDistributionContract.claimNFT(
      1,
      Worm,
      Worm,
      hex"ea6bad825c8a0a4a482e7ac4b3698ae3e00f16532b61b70833263d05b01382d964c18acafcbece6146f5b90fe5d1bd2b6e1f1e96fb0996d52df393f0afe535901c"
    );
    assertEq(ShadowContract.ownerOf(1), Worm);
    ShadowDistributionContract.claimNFT(
      1,
      Worm,
      Worm,
      hex"ea6bad825c8a0a4a482e7ac4b3698ae3e00f16532b61b70833263d05b01382d964c18acafcbece6146f5b90fe5d1bd2b6e1f1e96fb0996d52df393f0afe535901c"
    );
  }

  function testFailDifferentWallet() public {
    vm.prank(relayer, relayer);

    assertEq(ShadowContract.ownerOf(1), TombCouncil, "owner should be council");
    ShadowDistributionContract.claimNFT(
      1,
      Worm,
      unauthorizedUser,
      hex"ea6bad825c8a0a4a482e7ac4b3698ae3e00f16532b61b70833263d05b01382d964c18acafcbece6146f5b90fe5d1bd2b6e1f1e96fb0996d52df393f0afe535901c"
    );
    assertEq(ShadowContract.ownerOf(1), Worm);
  }

  function testOtherWallet() public {
    vm.prank(relayer, relayer);

    assertEq(ShadowContract.ownerOf(1), TombCouncil, "owner should be council");
    ShadowDistributionContract.claimNFT(
      1,
      Worm,
      otherWallet,
      hex"4d2fdb8d221c25a7c5ddaf831fd1a2818b3de2236ed389770aaee6f4776c3fe960e9487af1a65277ddfa1cb6ceb1f854d34c0b24fb3ae32c7f90be69ad90ebba1b"
    );
    assertEq(ShadowContract.ownerOf(1), otherWallet);
  }

  function testFailWrongWallet() public {
    vm.prank(relayer, relayer);

    assertEq(ShadowContract.ownerOf(1), TombCouncil, "owner should be council");
    ShadowDistributionContract.claimNFT(
      1,
      Worm,
      0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407,
      hex"4d2fdb8d221c25a7c5ddaf831fd1a2818b3de2236ed389770aaee6f4776c3fe960e9487af1a65277ddfa1cb6ceb1f854d34c0b24fb3ae32c7f90be69ad90ebba1b"
    );
  }
}
