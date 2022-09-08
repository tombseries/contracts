// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "solmate/utils/SafeTransferLib.sol";
import "openzeppelin/access/Ownable.sol";

interface IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

contract ShadowDistribution is Ownable {
  IERC721 internal _shadowContract;

  mapping(uint256 => address) ownerMapping;

  constructor(address shadowContract) {
    _shadowContract = IERC721(shadowContract);
  }

  function saveMapping(uint256[] calldata tokenIds, address[] calldata owners)
    public
    onlyOwner
  {
    if (tokenIds.length != owners.length) revert("Invalid input");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      ownerMapping[tokenIds[i]] = owners[i];
    }
  }
}
