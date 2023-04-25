// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../recovery/TombRecoveryGovernor.sol";

contract DeployRecoveryGovernor is Script {
    address public constant INDEX_MARKER_MAINNET = 0xa5c93e5d9eb8fb1B40228bb93fD40990913dB523;
    address constant INDEX_MARKER_GOERLI = 0x17DB883ed31582A82c69FeEe0B28ac662c877f00;
    address constant VOTE_AGGREGATOR_MAINNET = address(0);
    address constant VOTE_AGGREGATOR_GOERLI = address(0);

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
