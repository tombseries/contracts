// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GovernorCountingSimple} from "openzeppelin/governance/extensions/GovernorCountingSimple.sol";
import {IGovernor} from "openzeppelin/governance/IGovernor.sol";
import {EIP712Upgradeable} from "openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ERC721PresetMinterPauserAutoId} from "openzeppelin/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {ERC1967Proxy} from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import {RecoveryProxy} from "recovery-protocol/upgradeability/RecoveryProxy.sol";
import {RecoveryRegistry} from "recovery-protocol/RecoveryRegistry.sol";
import {RecoveryCollection} from "recovery-protocol/token/RecoveryCollection.sol";
import {RecoveryGovernor} from "recovery-protocol/governance/RecoveryGovernor.sol";
import {RecoveryTreasury} from "recovery-protocol/governance/RecoveryTreasury.sol";

import {MockOwnable721} from "../utils/MockOwnable721.sol";
import {TombRecoveryGovernor} from "../../recovery/TombRecoveryGovernor.sol";
import {IndexMarkerV2} from "../../IndexMarkerV2.sol";

contract TombRecoveryGovernorTest is Test, EIP712Upgradeable {
    IndexMarkerV2 indexMarker;
    RecoveryRegistry registry;
    MockOwnable721 aeon;
    MockOwnable721 tarot;
    TombRecoveryGovernor tombGovernorImplementation;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    address admin = address(0x1);
    address tombHolder = address(0x2);
    address voter = address(0x3);

    address[] tombContracts;

    function setUp() external {
        vm.startPrank(admin);

        indexMarker = IndexMarkerV2(
            address(
                new ERC1967Proxy(
                    address(new IndexMarkerV2()),
                    abi.encodeWithSignature(
                        "initialize(address,address,address,address,address)",
                        address(0),
                        address(0),
                        address(0),
                        admin,
                        address(0)
                    )
                )
            )
        );

        tombGovernorImplementation = new TombRecoveryGovernor(address(indexMarker));

        address collectionImpl = address(new RecoveryCollection());
        address governorImpl = address(new RecoveryGovernor());
        address treasuryImpl = address(new RecoveryTreasury());
        address registryImpl = address(new RecoveryRegistry(collectionImpl, governorImpl, treasuryImpl));

        registry = RecoveryRegistry(
            address(new RecoveryProxy(registryImpl, abi.encodeWithSignature("__RecoveryRegistry_init()")))
        );

        aeon = new MockOwnable721("test", "test");
        aeon.mint(tombHolder, 0);
        tarot = new MockOwnable721("test", "test");
        tarot.mint(tombHolder, 1);

        tombContracts = new address[](2);
        tombContracts[0] = address(aeon);
        tombContracts[1] = address(tarot);
        bool[] memory isTombContract = new bool[](2);
        isTombContract[0] = true;
        isTombContract[1] = true;
        indexMarker.setTombContracts(tombContracts, isTombContract);

        uint256[] memory tokenIds = new uint256[](10);
        address[] memory recipients = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            tokenIds[i] = i + 1;
            recipients[i] = voter;
        }
        recipients[9] = tombHolder;
        indexMarker.adminMint(tokenIds, recipients);
        vm.stopPrank();

        vm.prank(tombHolder);
        indexMarker.delegate(tombHolder);

        vm.prank(voter);
        indexMarker.delegate(voter);

        vm.roll(block.number + 1);
    }

    function test_Flow() external {
        vm.prank(admin);
        registry.registerParentCollection(
            address(aeon),
            address(indexMarker),
            address(tombGovernorImplementation),
            1,
            50400,
            172800,
            1,
            0,
            false,
            true,
            10
        );

        vm.prank(tombHolder);
        registry.createRecoveryCollectionForParentToken(address(aeon), 0, address(indexMarker));

        RecoveryRegistry.RecoveryCollectionAddresses memory addresses = registry.getRecoveryAddressesForParentToken(
            address(aeon),
            0
        );
        RecoveryCollection collection = RecoveryCollection(addresses.collection);
        RecoveryGovernor governor = RecoveryGovernor(addresses.governor);
        RecoveryTreasury treasury = RecoveryTreasury(addresses.treasury);

        address[] memory targets = new address[](1);
        targets[0] = address(collection);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("safeMint(address,string)", tombHolder, "https://test.com");
        vm.startPrank(tombHolder);
        uint256 proposalId = governor.propose(targets, values, calldatas, "");
        vm.roll(block.number + 2);
        uint256[] memory tombTokenIds = new uint256[](2);
        tombTokenIds[0] = 0;
        tombTokenIds[1] = 1;
        uint256 parentOwnerWeight = governor.castVoteWithReasonAndParams(
            proposalId,
            uint8(GovernorCountingSimple.VoteType.For),
            "",
            abi.encode(tombContracts, tombTokenIds)
        );
        assertEq(parentOwnerWeight, 12); // 10 from parent tomb + 1 other tomb + 1 index marker
        vm.stopPrank();

        vm.prank(voter);
        uint256 voterWeight = governor.castVote(proposalId, uint8(GovernorCountingSimple.VoteType.For));
        assertEq(voterWeight, 9);

        vm.roll(block.number + 50400);
        assertGt(block.number, governor.proposalDeadline(proposalId));
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        vm.prank(admin);
        governor.queue(targets, values, calldatas, keccak256(bytes("")));
        vm.warp(block.timestamp + 172800);
        governor.execute(targets, values, calldatas, keccak256(bytes("")));

        assertEq(collection.balanceOf(tombHolder), 1);
        assertEq(collection.tokenURI(1), "https://test.com");
    }
}
