// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../IndexMarkerV2.sol";

contract AdminMintIndexMarkers is Script {
    address public constant V2_INDEX_MARKER = 0xa5c93e5d9eb8fb1B40228bb93fD40990913dB523;
    address public constant COUNCIL_DAO = 0x1CC0271fe94c490B26d0f6369B1c947ecAd9b946;

    function run() public {
        IndexMarkerV2 marker = IndexMarkerV2(V2_INDEX_MARKER);
        uint256 tokenIdsFileLength = 242;
        uint256 BATCH_SIZE = 50;
        // prepare batches of tokenIds
        string memory line;
        uint256[][] memory tokenIdBatches = new uint256[][](tokenIdsFileLength / BATCH_SIZE + 1);
        for (uint256 i = 0; i < tokenIdBatches.length; i++) {
            if (i == tokenIdBatches.length - 1) {
                tokenIdBatches[i] = new uint256[](tokenIdsFileLength % BATCH_SIZE);
            } else {
                tokenIdBatches[i] = new uint256[](BATCH_SIZE);
            }
        }
        for (uint256 i = 0; i < tokenIdsFileLength; i++) {
            line = vm.readLine("./tokens.txt");
            tokenIdBatches[i / BATCH_SIZE][i % BATCH_SIZE] = parseInt(line);
        }

        uint256 deployerPrivateKey = vm.envUint("SHADOW_BEACON_RELAY_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        for (uint256 i = 0; i < tokenIdBatches.length; i++) {
            address[] memory destinationAddress = new address[](tokenIdBatches[i].length);
            for (uint256 j = 0; j < tokenIdBatches[i].length; j++) {
                destinationAddress[j] = COUNCIL_DAO;
            }

            if (tokenIdBatches[i].length == 0) {
                continue;
            }

            marker.adminMint(tokenIdBatches[i], destinationAddress);
        }

        vm.stopBroadcast();
    }

    function parseInt(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            if ((uint8(uint8(b[i])) >= 48) && (uint8(uint8(b[i])) <= 57)) {
                result = result * 10 + uint8(b[i]) - 48;
            }
        }
    }
}
