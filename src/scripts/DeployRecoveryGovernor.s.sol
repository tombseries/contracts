// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../recovery/TombRecoveryGovernor.sol";

contract DeployRecoveryGovernor is Script {
    address public constant INDEX_MARKER_MAINNET = 0xa5c93e5d9eb8fb1B40228bb93fD40990913dB523;
    address constant INDEX_MARKER_GOERLI = 0x17DB883ed31582A82c69FeEe0B28ac662c877f00;
    address constant VOTE_AGGREGATOR_MAINNET = 0xDCA75297e26353889f4BB7A66D6BfEB6DB8dFad0;
    address constant VOTE_AGGREGATOR_GOERLI = 0x6623884dA17E2A0BFf68773A5376292d5142AEe4;

    function run() public {
        if (block.chainid == 1) {
            run(INDEX_MARKER_MAINNET, VOTE_AGGREGATOR_MAINNET);
        } else if (block.chainid == 5) {
            run(INDEX_MARKER_GOERLI, VOTE_AGGREGATOR_GOERLI);
        } else {
            revert("Unsupported chain");
        }
    }

    function run(address indexMarker, address voteAggregator) public {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);
        require(voteAggregator != address(0), "Vote aggregator is required");

        new TombRecoveryGovernor(indexMarker, voteAggregator);

        vm.stopBroadcast();
    }
}
