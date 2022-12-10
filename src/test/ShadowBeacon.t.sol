// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { ShadowBeacon } from "../ShadowBeacon.sol";
import { DSTest } from "ds-test/test.sol";
import { Utilities } from "./utils/Utilities.sol";
import { console } from "./utils/Console.sol";
import { Vm } from "forge-std/Vm.sol";

contract ShadowBeaconTest is DSTest {
  ShadowBeacon internal beacon;
  Vm internal immutable vm = Vm(HEVM_ADDRESS);
  address signer = address(1234);

  function setUp() public {
    beacon = new ShadowBeacon(signer);
    vm.prank(signer, signer);
    beacon.transferFrom(address(0), address(1), 1);
  }

  function testFailSetApprovalForAll() public {
    vm.prank(address(1), address(1));
    beacon.setApprovalForAll(address(2421), true);
  }

  function testFailTransferFrom() public {
    vm.prank(address(1), address(1));
    beacon.transferFrom(address(1), address(2), 1);
  }

  function testFailSafeTransferFrom() public {
    vm.prank(address(1), address(1));
    beacon.safeTransferFrom(address(1), address(2), 1);
  }

  function testSignerTransferFrom() public {
    vm.prank(signer, signer);
    beacon.transferFrom(address(1), address(2), 1);
    assertEq(beacon.ownerOf(1), address(2));
  }

  function testSignerTransferFromMint() public {
    vm.prank(signer, signer);
    beacon.transferFrom(address(0), address(60), 60);
    assertEq(beacon.ownerOf(60), address(60));
  }
}
