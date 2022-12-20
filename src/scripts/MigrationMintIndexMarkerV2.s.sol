// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../IndexMarkerV2.sol";
import "../IndexMarker.sol";

contract MigrationMintIndexMarkerV2 is Script {
    uint256 public constant BATCH_SIZE = 50;
    address public constant INDEX_MARKER_V1_GOERLI = 0xC95Fb6E56B52A20693Ec98fb3b91F549C5eBECa8;
    address public constant INDEX_MARKER_V2_GOERLI = 0x17DB883ed31582A82c69FeEe0B28ac662c877f00;
    string public constant TOKEN_IDS_FILE_PATH_GOERLI = "./goerli-token-ids.txt";
    uint256 public constant TOKEN_IDS_FILE_LENGTH_GOERLI = 638;

    address public constant INDEX_MARKER_V1_MAINNET = 0x741d6BF0997A313720b5884F749685f7e9a994D6;
    address public constant INDEX_MARKER_V2_MAINNET = address(0);
    string public constant TOKEN_IDS_FILE_PATH_MAINNET = "./mainnet-token-ids.txt";
    uint256 public constant TOKEN_IDS_FILE_LENGTH_MAINNET = 0;

    function run() public {
        if (block.chainid == 1) {
            run(
                INDEX_MARKER_V1_MAINNET,
                INDEX_MARKER_V2_MAINNET,
                TOKEN_IDS_FILE_PATH_MAINNET,
                TOKEN_IDS_FILE_LENGTH_MAINNET
            );
        } else if (block.chainid == 5) {
            run(INDEX_MARKER_V1_GOERLI, INDEX_MARKER_V2_GOERLI, TOKEN_IDS_FILE_PATH_GOERLI, TOKEN_IDS_FILE_LENGTH_GOERLI);
        } else {
            revert("Unsupported chain");
        }
    }

    function run(
        address indexMarkerV1,
        address indexMarkerV2,
        string memory tokenIdsFilePath,
        uint256 tokenIdsFileLength
    ) public {
        require(indexMarkerV2 != address(0), "indexMarkerV2 not set");

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
            line = vm.readLine(tokenIdsFilePath);
            tokenIdBatches[i / BATCH_SIZE][i % BATCH_SIZE] = parseInt(line);
        }

        // send mint transactions
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        for (uint256 i = 0; i < tokenIdBatches.length; i++) {
            IndexMarkerV2(indexMarkerV2).migrationMint(tokenIdBatches[i]);
        }
        vm.stopBroadcast();

        // confirm mints
        for (uint256 i = 0; i < tokenIdsFileLength; i++) {
            uint256 tokenId = tokenIdBatches[i / BATCH_SIZE][i % BATCH_SIZE];
            require(
                IndexMarkerV2(indexMarkerV2).ownerOf(tokenId) == IndexMarker(indexMarkerV1).ownerOf(tokenId),
                "Migration failed"
            );
        }
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
