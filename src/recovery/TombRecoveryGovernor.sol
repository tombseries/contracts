// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {RecoveryGovernor} from "recovery-protocol/governance/RecoveryGovernor.sol";
import {IndexMarkerV2} from "../IndexMarkerV2.sol";

// import index marker

contract TombRecoveryGovernor is RecoveryGovernor {
    address constant INDEX_MARKER_GOERLI = 0x17DB883ed31582A82c69FeEe0B28ac662c877f00;
    address constant INDEX_MARKER_MAINNET = 0xa5c93e5d9eb8fb1B40228bb93fD40990913dB523;

    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public tombVotedOnProposal;

    function _indexMarker() internal view returns (IndexMarkerV2) {
        if (block.chainid == 5) {
            return IndexMarkerV2(INDEX_MARKER_GOERLI);
        } else if (block.chainid == 1) {
            return IndexMarkerV2(INDEX_MARKER_MAINNET);
        } else {
            revert("TombRecoveryGovernor: unsupported chain");
        }
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal override returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");
        uint256 weight = _getVotes(account, proposalSnapshot(proposalId), params);
        if (params.length > 0) {
            (address[] memory tombContracts, uint256[] memory tombTokenIds) = abi.decode(params, (address[], uint256[]));
            for (uint256 i = 0; i < tombTokenIds.length; i++) {
                if (!_indexMarker().isTomb(tombContracts[i], tombTokenIds[i])) {
                    revert("TombRecoveryGovernor: token provided is not a tomb");
                }
                if (IERC721Upgradeable(tombContracts[i]).ownerOf(tombTokenIds[i]) != account) {
                    revert("TombRecoveryGovernor: token provided is not owned by voter");
                }
                if (tombVotedOnProposal[tombContracts[i]][tombTokenIds[i]][proposalId]) {
                    revert("TombRecoveryGovernor: tomb already voted on proposal");
                }
                tombVotedOnProposal[tombContracts[i]][tombTokenIds[i]][proposalId] = true;
                weight += 1;
            }
        }

        if (account == recoveryParentTokenOwner()) {
            require(
                !recoveryParentTokenOwnerVotedOnProposal[proposalId],
                "Governor: recovery parent token owner already voted on proposal"
            );
            recoveryParentTokenOwnerVotedOnProposal[proposalId] = true;
            weight += recoveryParentTokenOwnerVotingWeight;
        }
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    // extra storage
    uint256[50] private __gap;
}
