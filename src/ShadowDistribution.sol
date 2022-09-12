//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????:
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B ~@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7
//    Y@@@@@#                                                                ~@@@@@@ P@@@@@G
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ ~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.!B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B
//         ...........................B@@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&5JJJJJJJJJJJJJJJJJJJYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJY@@@@@@!
//    5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^

//  _______________________________________________________ Tomb Series  ___________________________________________________

// Shadow Distribution
// Contract by Luke Miles (@worm_emoji)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/access/Ownable.sol";

interface SIERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract ShadowDistribution is Ownable {
  SIERC721 internal _shadowContract;
  address internal _councilWallet;
  mapping(uint256 => address) public ownerMapping;

  event Claimed(uint256 tokenId, address winner, address destination);
  event WinnerStored(uint256 tokenId, address winner);

  constructor(address shadowContract, address councilWallet) {
    _shadowContract = SIERC721(shadowContract);
    _councilWallet = councilWallet;
  }

  function setCouncilWallet(address councilWallet) public onlyOwner {
    _councilWallet = councilWallet;
  }

  function saveMapping(uint256[] calldata tokenIds, address[] calldata owners)
    public
    onlyOwner
  {
    if (tokenIds.length != owners.length) revert("Invalid input");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      emit WinnerStored(tokenIds[i], owners[i]);
      ownerMapping[tokenIds[i]] = owners[i];
    }
  }

  function makeHash(uint256 tokenID, address destination)
    internal
    pure
    returns (bytes32)
  {
    return
      ECDSA.toEthSignedMessageHash(
        abi.encodePacked(
          "This message confirms that this wallet owner has been allocated ownership of Tomb #",
          Strings.toString(tokenID),
          " in the SHADOW House. Signing this message will initiate a transfer to the following wallet address, which I confirm is Polygon-compatible: ",
          Strings.toHexString(destination)
        )
      );
  }

  function claimNFT(
    uint256 tokenID,
    address winner,
    address destination,
    bytes memory sig
  ) public {
    address approvedAddress = ownerMapping[tokenID];
    require(approvedAddress == winner, "Invalid winner");

    (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
      makeHash(tokenID, destination),
      sig
    );
    require(
      error == ECDSA.RecoverError.NoError &&
        recovered == approvedAddress &&
        recovered == winner,
      "Invalid signature"
    );

    ownerMapping[tokenID] = address(0);
    emit Claimed(tokenID, winner, destination);
    _shadowContract.safeTransferFrom(_councilWallet, destination, tokenID);
  }
}
