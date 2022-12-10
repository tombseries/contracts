// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC1967Proxy} from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {IndexMarkerV2} from "../IndexMarkerV2.sol";

contract IndexMarkerV2Test is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    address internal marker;
    Utilities internal utils;
    address payable[] internal users;
    bytes internal sig;

    function setUp() public {
        IndexMarkerV2 markerImpl = new IndexMarkerV2();
        marker = address(
            new ERC1967Proxy(
                address(markerImpl),
                abi.encodeWithSignature("initialize(address,address,string)", address(0x1), address(0x2), "test")
            )
        );
        IndexMarkerV2(marker).setMintAllowedAndExpiry(true, 1672531199);
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

    //   function testFailPremint() public {
    //     // try to premint without waiting too long
    //     vm.warp(1655678279);
    //     bytes32 hash = keccak256(abi.encodePacked(uint256(100), sig, msg.sender));
    //     vm.prank(0x00a329c0648769A73afAc7F9381E08FB43dBEA72);
    //     marker.premint(hash);
    //     vm.prank(0x00a329c0648769A73afAc7F9381E08FB43dBEA72);
    //     vm.warp(1655678279);
    //     marker.mint(100, sig);
    //   }

    //   function testRoyaltyInfo() public {
    //     (address dest, uint256 royalty) = marker.royaltyInfo(0, 150);
    //     assertEq(dest, address(marker));
    //     assertEq(royalty, 15);
    //   }
}
