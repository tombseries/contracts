// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { DSTest } from "ds-test/test.sol";
import { Utilities } from "./utils/Utilities.sol";
import { console } from "./utils/Console.sol";
import { Vm } from "forge-std/Vm.sol";
import { IndexMarker } from "../IndexMarker.sol";
import { TombIndex } from "../TombIndex.sol";

contract CatTest is DSTest {
  Vm internal immutable vm = Vm(HEVM_ADDRESS);
  IndexMarker internal marker;
  TombIndex internal index;
  Utilities internal utils;
  address payable[] internal users;
  bytes internal sig;

  function setUp() public {
    index = new TombIndex(
      "https://tombseri.es/img/",
      0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46
    );
    marker = new IndexMarker(
      0x818d7CA5aa6E964784267aAaEAEab323d5894A86,
      "https://tombseri.es",
      address(index),
      msg.sender
    );
    marker.setMintInformation(true, 1672531199);
    utils = new Utilities();
    users = utils.createUsers(5);
    sig = hex"be6f3b9f9b009848f4245269a8b532a47bac1cd3a38880907c897b41176cce2bf63ac6f53ab8efb0bf2fafe9cc8b94dee65a6ba3a94699426d1dfd4d57590dcf";
  }

  // function testPremint() public {
  //   vm.warp(1655678279);
  //   bytes32 hash = keccak256(abi.encodePacked(uint256(100), sig, msg.sender));
  //   vm.prank(0x00a329c0648769A73afAc7F9381E08FB43dBEA72);
  //   marker.premint(hash);
  //   vm.prank(0x00a329c0648769A73afAc7F9381E08FB43dBEA72);
  //   vm.warp(1655678340);
  //   marker.mint(100, sig);
  // }

  function testFailPremint() public {
    // try to premint without waiting too long
    vm.warp(1655678279);
    bytes32 hash = keccak256(abi.encodePacked(uint256(100), sig, msg.sender));
    vm.prank(0x00a329c0648769A73afAc7F9381E08FB43dBEA72);
    marker.premint(hash);
    vm.prank(0x00a329c0648769A73afAc7F9381E08FB43dBEA72);
    vm.warp(1655678279);
    marker.mint(100, sig);
  }

  //   function testRoyaltyInfo() public {
  //     (address dest, uint256 royalty) = marker.royaltyInfo(0, 150);
  //     assertEq(dest, address(marker));
  //     assertEq(royalty, 15);
  //   }
}
