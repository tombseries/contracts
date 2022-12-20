// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "../IndexMarkerV2.sol";

contract DeployIndexMarkerV2 is Script {
    address public constant MARKET_FILTER_DAO_ADDRESS_GOERLI = 0x9b866b819376cb5c19c510edAAAbA9BA44e8b87c;
    address public constant INDEX_MARKER_V1_GOERLI = 0xC95Fb6E56B52A20693Ec98fb3b91F549C5eBECa8;
    address public constant TOMB_INDEX_GOERLI = 0xeC0a7349dC663a4C2363E72ee9de5aE24FA01163;

    address public constant SIGNER_MAINNET = 0x7176E0d59a8bF299d57c6f4809ce88FB11D1cc31;
    address payable public constant ROYALTY_RECIPIENT_MAINNET = payable(0x9699b55a6e3093D76F1147E936a2d59EC3a3B0B3);
    address public constant MARKET_FILTER_DAO_ADDRESS_MAINNET = 0x3AE2804De4A54283601Db24a897856D9772eA0D8;
    address public constant INDEX_MARKER_V1_MAINNET = 0x741d6BF0997A313720b5884F749685f7e9a994D6;
    address public constant TOMB_INDEX_MAINNET = 0x185E8a578bF6896e3988e7c38a6A23889CA2aF9f;

    function run() public {
        if (block.chainid == 1) {
            run(
                SIGNER_MAINNET,
                ROYALTY_RECIPIENT_MAINNET,
                INDEX_MARKER_V1_MAINNET,
                MARKET_FILTER_DAO_ADDRESS_MAINNET,
                TOMB_INDEX_MAINNET
            );
        } else if (block.chainid == 5) {
            address payable owner = payable(vm.envAddress("DEPLOYER_ADDRESS"));
            run(owner, owner, INDEX_MARKER_V1_GOERLI, MARKET_FILTER_DAO_ADDRESS_GOERLI, TOMB_INDEX_GOERLI);
        } else {
            revert("Unsupported chain");
        
    }

    function run(
        address signer,
        address payable royaltyRecipient,
        address indexMarkerV1,
        address marketFilterDAO,
        address tombIndex
    ) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IndexMarkerV2 implementation = new IndexMarkerV2();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address)",
                marketFilterDAO,
                signer,
                indexMarkerV1,
                royaltyRecipient,
                tombIndex
            )
        );

        // IndexMarkerV2(address(proxy)).manageMarketFilterDAOSubscription(true);

        vm.stopBroadcast();
    }
}
