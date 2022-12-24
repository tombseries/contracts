// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../ShadowBeacon.sol";
import "../ShadowNFT.sol";

contract SyncShadowBeacon is Script {
    address public constant SHADOW_BEACON_GOERLI = 0x975cED3A79e4FCc48B6E309A286DC49A4Bc44042;
    address public constant CANONICAL_SHADOW_MUMBAI = 0xA6C299948F095C2dCD7d0e6a3b7B2C7AaD0e28b4;
    string public goerliRPCUrl = vm.envString("GOERLI_RPC_URL");
    string public mumbaiRPCUrl = vm.envString("MUMBAI_RPC_URL");

    address public constant SHADOW_BEACON_MAINNET = 0x819c573D8d8BE12095606Cb846E81913F2cDd140;
    address public constant CANONICAL_SHADOW_POLYGON = 0xE877CDACBB7827d4232Cde5f8de58371F144a0A4;
    string public mainnetRPCUrl = vm.envString("MAINNET_RPC_URL");
    string public polygonRPCUrl = vm.envString("POLYGON_RPC_URL");

    function run() public {
        if (block.chainid == 1) {
            run(SHADOW_BEACON_MAINNET, CANONICAL_SHADOW_POLYGON, mainnetRPCUrl, polygonRPCUrl);
        } else {
            run(SHADOW_BEACON_GOERLI, CANONICAL_SHADOW_MUMBAI, goerliRPCUrl, mumbaiRPCUrl);
        }
    }

    function run(
        address beaconAddress,
        address canonicalShadowAddress,
        string memory beaconRpcUrl,
        string memory canonicalShadowRpcUrl
    ) public {
        uint256 shadowRPC = vm.createFork(canonicalShadowRpcUrl);
        uint256 beaconRPC = vm.createFork(beaconRpcUrl);

        address[] memory canonicalOwners = new address[](36);

        vm.selectFork(shadowRPC);
        Shadow shadowNFT = Shadow(canonicalShadowAddress);

        for (uint256 i = 0; i < 36; i++) {
            canonicalOwners[i] = shadowNFT.ownerOf(i + 1);
        }

        vm.selectFork(beaconRPC);
        ShadowBeacon beacon = ShadowBeacon(beaconAddress);

        uint256 deployerPrivateKey = vm.envUint("SHADOW_BEACON_RELAY_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        for (uint256 i = 0; i < 36; i++) {
            address owner = beacon.ownerOf(i + 1);
            if (owner != canonicalOwners[i]) {
                beacon.transferFrom(owner, canonicalOwners[i], i + 1);
            }
        }
        vm.stopBroadcast();
    }
}
