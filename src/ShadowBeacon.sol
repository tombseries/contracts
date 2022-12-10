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

// Shadow Beacon
// Contract by Luke Miles (@worm_emoji)
// SPDX-License-Identifier: MIT

import "solmate/tokens/ERC721.sol";
import "openzeppelin/utils/Strings.sol";
import "openzeppelin/access/Ownable.sol";

pragma solidity >=0.8.10;

contract ShadowBeacon is ERC721, Ownable {
  string public baseURI;
  address public allowedSigner;

  constructor(address _allowedSigner) ERC721("Shadow Beacon", "SHDB") {
    allowedSigner = _allowedSigner;
  }

  // Admin functions //

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setAllowedSigner(address _allowedSigner) public onlyOwner {
    allowedSigner = _allowedSigner;
  }

  // Signer functions //

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    require(msg.sender == allowedSigner, "ONLY_ALLOWED_SIGNER");
    require(from == ownerOf[id], "WRONG_FROM");

    if (ownerOf[id] == address(0)) {
      _mint(to, id);
      return;
    }

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      balanceOf[from]--;
      balanceOf[to]++;
    }

    ownerOf[id] = to;
    emit Transfer(from, to, id);
  }

  // View functions //

  function tokenURI(uint256 tokenID)
    public
    view
    override
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
  }

  // Disabled functions //

  function approve(address, uint256) public pure override {
    revert("NON_TRANSFERABLE");
  }

  function setApprovalForAll(address, bool) public pure override {
    revert("NON_TRANSFERABLE");
  }

  function safeTransferFrom(
    address,
    address,
    uint256
  ) public pure override {
    revert("NON_TRANSFERABLE");
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public pure override {
    revert("NON_TRANSFERABLE");
  }
}
