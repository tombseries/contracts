// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC1967Proxy} from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {OperatorFilterRegistry} from "zora-drops-contracts/test/filter/OperatorFilterRegistry.sol";
import {OperatorFilterRegistryErrorsAndEvents} from "zora-drops-contracts/test/filter/OperatorFilterRegistryErrorsAndEvents.sol";
import {OwnedSubscriptionManager} from "zora-drops-contracts/src/filter/OwnedSubscriptionManager.sol";
import {DSTest} from "ds-test/test.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {IndexMarkerV2} from "../IndexMarkerV2.sol";
import {IndexMarker} from "../IndexMarker.sol";
import {TombIndex} from "../TombIndex.sol";

contract IndexMarkerV2Test is DSTest {
    address payable public constant TOMB_ARTIST = payable(0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    uint256 internal constant SIGNER_PK = 1;
    address internal signer;
    address payable internal royaltyRecipient = payable(address(0x1234));
    address public ownedSubscriptionManager;
    address internal markerV2;
    address internal markerV1;
    address internal tombIndex;
    address internal constant OPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);
    address internal constant ADMIN = address(0x789);

    event Upgraded(address indexed implementation);

    function setUp() public {
        signer = vm.addr(SIGNER_PK);
        vm.etch(address(0x000000000000AAeB6D7670E522A718067333cd4E), address(new OperatorFilterRegistry()).code);
        ownedSubscriptionManager = address(new OwnedSubscriptionManager(address(0x123456)));
        tombIndex = address(new TombIndex("https://imageuri.com/", TOMB_ARTIST));
        markerV1 = address(new IndexMarker(signer, "https://baseuri.com/", tombIndex, royaltyRecipient));
        IndexMarker(markerV1).setMintInformation(true, 1672531199);
        IndexMarker(markerV1).transferOwnership(ADMIN);
        markerV2 = address(
            new ERC1967Proxy(
                address(new IndexMarkerV2()),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address,address)",
                    ownedSubscriptionManager,
                    signer,
                    markerV1,
                    royaltyRecipient,
                    tombIndex
                )
            )
        );
        IndexMarkerV2(markerV2).setMintAllowedAndExpiry(true, 1672531199);
        IndexMarkerV2(markerV2).transferOwnership(ADMIN);
    }

    function mintV1(uint256 tokenID, address dest) public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, keccak256(abi.encodePacked(uint256(tokenID))));
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes32 hash = keccak256(abi.encodePacked(uint256(tokenID), sig, dest));
        vm.prank(dest);
        IndexMarker(markerV1).premint(hash);
        vm.prank(dest);
        vm.warp(block.timestamp + 100);
        IndexMarker(markerV1).mint(tokenID, sig);
    }

    function mint(uint256 tokenID, address dest) public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, keccak256(abi.encodePacked(uint256(tokenID))));
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes32 hash = keccak256(abi.encodePacked(uint256(tokenID), sig, dest));
        vm.prank(dest);
        IndexMarkerV2(markerV2).premint(hash);
        vm.prank(dest);
        vm.warp(block.timestamp + 100);
        IndexMarkerV2(markerV2).mint(tokenID, sig);
    }

    function testTokenURI() public {
        assertEq(IndexMarkerV2(markerV2).tokenURI(0), TombIndex(tombIndex).tokenURI(21));

        mint(1, msg.sender);
        assertEq(
            IndexMarkerV2(markerV2).tokenURI(1),
            string(abi.encodePacked("ipfs://QmYZEr3xvwdd5v5wbFR4LEDrqaBRLG3gXg5uC6SK37GfaQ/", Strings.toString(1)))
        );
    }

    function testSetBaseURI() public {
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setBaseURI("https://newbaseuri.com/");
        assertEq(IndexMarkerV2(markerV2).baseURI(), "https://newbaseuri.com/");
    }

    function testRevertSetBaseURINotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).setBaseURI("https://newbaseuri.com/");
    }

    function testMigrationMint() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        address[] memory owners = new address[](2);
        owners[0] = address(0x1);
        owners[1] = address(0x2);
        mintV1(tokenIds[0], owners[0]);
        mintV1(tokenIds[1], owners[1]);
        assertEq(IndexMarker(markerV1).ownerOf(tokenIds[0]), owners[0]);
        assertEq(IndexMarker(markerV1).ownerOf(tokenIds[1]), owners[1]);
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).migrationMint(tokenIds);
        assertEq(IndexMarkerV2(markerV2).ownerOf(tokenIds[0]), owners[0]);
        assertEq(IndexMarkerV2(markerV2).ownerOf(tokenIds[1]), owners[1]);
    }

    function testRevertMigrationMintNotOwner() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        address[] memory owners = new address[](2);
        owners[0] = address(0x1);
        owners[1] = address(0x2);
        mintV1(tokenIds[0], owners[0]);
        mintV1(tokenIds[1], owners[1]);
        assertEq(IndexMarker(markerV1).ownerOf(tokenIds[0]), owners[0]);
        assertEq(IndexMarker(markerV1).ownerOf(tokenIds[1]), owners[1]);
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).migrationMint(tokenIds);
    }

    function testAdminMint() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        address[] memory owners = new address[](2);
        owners[0] = address(0x1);
        owners[1] = address(0x2);

        vm.startPrank(ADMIN);
        IndexMarkerV2(markerV2).setMintAllowedAndExpiry(false, 1672531199);
        IndexMarkerV2(markerV2).adminMint(tokenIds, owners);
        vm.stopPrank();

        assertEq(IndexMarkerV2(markerV2).ownerOf(tokenIds[0]), owners[0]);
        assertEq(IndexMarkerV2(markerV2).ownerOf(tokenIds[1]), owners[1]);
    }

    function testRevertAdminMintNotOwner() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        address[] memory owners = new address[](2);
        owners[0] = address(0x1);
        owners[1] = address(0x2);
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setMintAllowedAndExpiry(false, 1672531199);

        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).adminMint(tokenIds, owners);
    }

    function testMint() public {
        address minter = address(0x1);
        mint(100, minter);
        assertEq(IndexMarkerV2(markerV2).ownerOf(100), minter);
    }

    function testRevertMintWithoutWaiting() public {
        address minter = address(0x1);
        vm.warp(1655678279);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, keccak256(abi.encodePacked(uint256(100))));
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes32 hash = keccak256(abi.encodePacked(uint256(100), sig, minter));
        vm.prank(minter);
        IndexMarkerV2(markerV2).premint(hash);
        vm.prank(minter);
        vm.warp(1655678280);
        vm.expectRevert("IndexMarker: Claim is too new");
        IndexMarkerV2(markerV2).mint(100, sig);
    }

    function testCanMint() public {
        assertTrue(IndexMarkerV2(markerV2).isMintAllowed());
        assertEq(IndexMarkerV2(markerV2).mintExpiry(), uint256(1672531199));
        assertTrue(IndexMarkerV2(markerV2).canMint());

        vm.startPrank(ADMIN);
        IndexMarkerV2(markerV2).setMintAllowedAndExpiry(false, 1672531199);
        assertEq(IndexMarkerV2(markerV2).mintExpiry(), uint256(1672531199));
        assertTrue(!IndexMarkerV2(markerV2).canMint());
        IndexMarkerV2(markerV2).setMintAllowedAndExpiry(true, 1672531199);
        vm.stopPrank();

        vm.warp(1672531200);
        assertTrue(!IndexMarkerV2(markerV2).canMint());
    }

    function testSetTokenClaimSigner() public {
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setTokenClaimSigner(address(0x1));
        assertEq(IndexMarkerV2(markerV2).tokenClaimSigner(), address(0x1));
    }

    function testRevertSetTokenClaimSignerNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).setTokenClaimSigner(address(0x1));
    }

    function testRoyaltyInfo() public {
        (address dest, uint256 royalty) = IndexMarkerV2(markerV2).royaltyInfo(0, 150);
        assertEq(dest, address(TOMB_ARTIST));
        assertEq(royalty, 15);

        (dest, royalty) = IndexMarkerV2(markerV2).royaltyInfo(1, 150);
        assertEq(dest, address(royaltyRecipient));
        assertEq(royalty, 15);
    }

    function testSetDefaultRoyalty() public {
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setDefaultRoyalty(address(0x1), 2_000);

        (address dest, uint256 royalty) = IndexMarkerV2(markerV2).royaltyInfo(1, 200);
        assertEq(dest, address(0x1));
        assertEq(royalty, 40);
    }

    function testRevertSetDefaultRoyaltyNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).setDefaultRoyalty(address(0x1), 2_000);
    }

    function testDeleteDefaultRoyalty() public {
        vm.startPrank(ADMIN);
        IndexMarkerV2(markerV2).setDefaultRoyalty(address(0x1), 2_000);
        IndexMarkerV2(markerV2).deleteDefaultRoyalty();
        vm.stopPrank();

        (address dest, uint256 royalty) = IndexMarkerV2(markerV2).royaltyInfo(1, 200);
        assertEq(dest, address(0));
        assertEq(royalty, 0);
    }

    function testRevertDeleteDefaultRoyaltyNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).deleteDefaultRoyalty();
    }

    function testSetTokenRoyalty() public {
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setTokenRoyalty(1, address(0x2), 2_000);

        (address dest, uint256 royalty) = IndexMarkerV2(markerV2).royaltyInfo(1, 200);
        assertEq(dest, address(0x2));
        assertEq(royalty, 40);
    }

    function testRevertSetTokenRoyaltyNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).setTokenRoyalty(1, address(0x2), 2_000);
    }

    function testResetTokenRoyalty() public {
        vm.startPrank(ADMIN);
        IndexMarkerV2(markerV2).setTokenRoyalty(1, address(0x2), 2_000);
        IndexMarkerV2(markerV2).resetTokenRoyalty(1);
        vm.stopPrank();

        (address dest, uint256 royalty) = IndexMarkerV2(markerV2).royaltyInfo(1, 150);
        assertEq(dest, address(royaltyRecipient));
        assertEq(royalty, 15);
    }

    function testRevertResetTokenRoyaltyNotOwner() public {
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setTokenRoyalty(1, address(0x2), 2_000);

        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).resetTokenRoyalty(1);
    }

    function testUpdateMarketFilterSettings() public {
        vm.prank(ADMIN);
        bytes memory baseCall = abi.encodeWithSelector(OperatorFilterRegistry.register.selector, address(markerV2));
        IndexMarkerV2(markerV2).updateMarketFilterSettings(baseCall);
        assertTrue(OperatorFilterRegistry(OPERATOR_FILTER_REGISTRY).isRegistered(address(markerV2)));
    }

    function testRevertUpdateMarketFilterSettingsNotOwner() public {
        bytes memory baseCall = abi.encodeWithSelector(OperatorFilterRegistry.register.selector, address(markerV2));
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).updateMarketFilterSettings(baseCall);
        assertTrue(!OperatorFilterRegistry(OPERATOR_FILTER_REGISTRY).isRegistered(address(markerV2)));
    }

    function testManageMarketFilterDAOSubscription() public {
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).manageMarketFilterDAOSubscription(true);
        assertEq(
            OperatorFilterRegistry(OPERATOR_FILTER_REGISTRY).subscriptionOf(address(markerV2)),
            address(ownedSubscriptionManager)
        );
    }

    function testRevertManageMarketFilterDAOSubscriptionNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        IndexMarkerV2(markerV2).manageMarketFilterDAOSubscription(true);
        vm.expectRevert();
        OperatorFilterRegistry(OPERATOR_FILTER_REGISTRY).subscriptionOf(address(markerV2));
    }

    function testSetTombContracts() public {
        address[] memory tombContracts = new address[](2);
        tombContracts[0] = address(0x1);
        tombContracts[1] = address(0x2);
        bool[] memory isTombContract = new bool[](2);
        isTombContract[0] = true;
        isTombContract[1] = true;
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setTombContracts(tombContracts, isTombContract);
        assertTrue(IndexMarkerV2(markerV2).isTomb(address(0x1), 0));
        assertTrue(IndexMarkerV2(markerV2).isTomb(address(0x2), 0));
    }

    function testSetTombTokens() public {
        address[] memory tombContracts = new address[](2);
        tombContracts[0] = address(0x1);
        tombContracts[1] = address(0x2);
        uint256[] memory tombTokenIDs = new uint256[](2);
        tombTokenIDs[0] = 1;
        tombTokenIDs[1] = 2;
        bool[] memory isTombToken = new bool[](2);
        isTombToken[0] = true;
        isTombToken[1] = true;
        vm.prank(ADMIN);
        IndexMarkerV2(markerV2).setTombTokens(tombContracts, tombTokenIDs, isTombToken);
        assertTrue(IndexMarkerV2(markerV2).isTomb(address(0x1), 1));
        assertTrue(IndexMarkerV2(markerV2).isTomb(address(0x2), 2));
    }

    function testUpgrade() public {
        address newImpl = address(new IndexMarkerV2());
        vm.prank(ADMIN);
        vm.expectEmit(true, false, false, false);
        emit Upgraded(newImpl);
        IndexMarkerV2(markerV2).upgradeTo(newImpl);
    }
}
