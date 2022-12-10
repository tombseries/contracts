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

//  _____________________________________________________ Tomb Series  _____________________________________________________

//       :!JYYYYJ!.                   .JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.   7YYYYYYYYY?~.              ^JYYYYYYYYY^
//     ~&@@@@@@@@@@#7.                ?@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P  &@@@@@@@@@@@@B!           :@@@@@@@@@@@5
//    ^@@@@@@BB@@@@@@@B!              ?@@@@@&PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@@@# JGGGGGGG#@@@@@@@G^         !PGGGGGGGGG!
//    5@@@@@5  .7#@@@@@@@P^           ?@@@@@P                                .@@@@@@.         .J&@@@@@@&5:
//    Y@@@@@Y     .J&@@@@@@&5:        ?@@@@@G                                 @@@@@@.            :Y&@@@@@@&J.
//    Y@@@@@5        :5&@@@@@@&J.     ?@@@@@G                                 @@@@@@.               ^P@@@@@@@#7.
//    Y@@@@@5           ^P@@@@@@@#7.  J@@@@@G                                 @@@@@@.                  ~G@@@@@@@B!
//    Y@@@@@5              ~B@@@@@@@BG@@@@@@! PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@# JGPPPPPPPP5:        .7#@@@@@@@GPPPPPPG~
//    5@@@@@5                .7#@@@@@@@@@@&! .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G  &@@@@@@@@@@&           .J&@@@@@@@@@@@@5
//    ^5YYY5~                   .!JYYYYY7:    Y5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~.   ?5YYYYYYY5J.              :7JYYYYYYYY5^

//  __________________________________________________ Tomb Index Marker ___________________________________________________

//  _______________________________________________ Deployed by TERRAIN 2022 _______________________________________________

//  ___________________________________________ All tombs drawn by David Rudnick ___________________________________________

//  ___________________________________ Contract architects: James Geary and Luke Miles ____________________________________

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "zora-drops-contracts/interfaces/IOperatorFilterRegistry.sol";
import "./utils/IERC173.sol";
import "./utils/IRecoveryChildV1.sol";

contract IndexMarkerV2 is
  Initializable,
  ERC721Upgradeable,
  AccessControlUpgradeable,
  EIP712Upgradeable,
  ERC721VotesUpgradeable,
  ERC2981Upgradeable,
  UUPSUpgradeable,
  IERC173
{
  uint16 internal constant DEFAULT_TOMB_HOLDER_VOTING_WEIGHT = 30; // 30 votes
  uint96 internal constant DEFAULT_ROYALTY_BPS = 1_000; // 10%
  uint16 internal constant MAX_SUPPLY = 3_000;

  address payable internal constant TOMB_ARTIST =
    payable(0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);
  address payable internal constant INITIAL_ROYALTY_DESTINATION =
    payable(0x9699b55a6e3093D76F1147E936a2d59EC3a3B0B3);
  IOperatorFilterRegistry public immutable operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
  address public marketFilterDAOAddress;

  address public tokenClaimSigner;
  uint256 public mintExpiry; // Sat Dec 31 2022 23:59:59 GMT+0000
  bool public isMintAllowed;
  string public baseURI;
  mapping(bytes32 => uint256) public premintTimes;
  mapping(address => bool) public isTombContract;
  mapping(address => mapping(uint256 => bool)) public isSingletonTombToken;
  address internal erc173Owner;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _marketFilterDAOAddress,
    address _tokenClaimSigner,
    string calldata _metadataBaseURI
  ) public initializer onlyRole(DEFAULT_ADMIN_ROLE) {
    __ERC721_init("Tomb Index Marker", "MKR");
    __AccessControl_init();
    __EIP712_init("Tomb Index Marker", "1");
    __ERC721Votes_init();
    __UUPSUpgradeable_init();
    __ERC2981_init();

    // initialize RONIN
    _mint(_msgSender(), 0);

    mintExpiry = 1672531199;
    isMintAllowed = false;
    marketFilterDAOAddress = _marketFilterDAOAddress;
    tokenClaimSigner = _tokenClaimSigner;
    baseURI = _metadataBaseURI;
    _setTokenRoyalty(0, TOMB_ARTIST, DEFAULT_ROYALTY_BPS);
    _setDefaultRoyalty(INITIAL_ROYALTY_DESTINATION, DEFAULT_ROYALTY_BPS);

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /// TOKEN AND MINTING ///

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseURI) external {
    baseURI = newBaseURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable) {
    if (
      from != _msgSender() && address(operatorFilterRegistry).code.length > 0
    ) {
      require(
        operatorFilterRegistry.isOperatorAllowed(address(this), _msgSender()),
        "WrappedIndexMarker: operator not allowed"
      );
    }

    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable, ERC721VotesUpgradeable) {
    super._afterTokenTransfer(from, to, tokenId, batchSize);
  }

  function adminMint(uint256[] calldata tokenIds, address[] calldata recipients)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(tokenIds.length == recipients.length, "IndexMarker: invalid input");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(tokenIds[i] <= MAX_SUPPLY, "Index is too high");
      _mint(recipients[i], tokenIds[i]);
    }
  }

  function canMint() public view returns (bool) {
    return isMintAllowed && mintExpiry > block.timestamp;
  }

  function calculateMintHash(
    uint256 tokenId,
    bytes memory signature,
    address sender
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenId, signature, sender));
  }

  function premint(bytes32 _hash) public {
    require(premintTimes[_hash] == 0, "Can't override hash value");
    premintTimes[_hash] = block.timestamp;
  }

  function mint(uint256 tokenId, bytes memory signature) public {
    require(canMint(), "Public minting is not active");
    require(tokenId <= MAX_SUPPLY, "Index is too high");
    bytes32 mintHash = calculateMintHash(tokenId, signature, _msgSender());
    uint256 premintTime = premintTimes[mintHash];
    require(premintTime != 0, "Token is not preminted");

    require(block.timestamp - premintTime > 60, "Claim is too new");

    (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable
      .tryRecover(keccak256(abi.encodePacked(tokenId)), signature);
    require(
      error == ECDSAUpgradeable.RecoverError.NoError &&
        recovered == tokenClaimSigner,
      "Invalid signature"
    );

    _mint(msg.sender, tokenId);
  }

  function updateSigner(address _tokenClaimSigner)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    tokenClaimSigner = _tokenClaimSigner;
  }

  function setMintAllowedAndExpiry(bool _isMintAllowed, uint256 _expiry)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    isMintAllowed = _isMintAllowed;
    mintExpiry = _expiry;
  }

  /// ROYALTIES ///

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function resetTokenRoyalty(uint256 tokenId)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _resetTokenRoyalty(tokenId);
  }

  /// CENTRALIZED PLATFORM FEES AND SETTINGS ///

  function transferOwnership(address _newManager)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    emit OwnershipTransferred(erc173Owner, _newManager);
    erc173Owner = _newManager;
  }

  function owner() external view returns (address) {
    return erc173Owner;
  }

  function updateMarketFilterSettings(bytes calldata args)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    returns (bytes memory)
  {
    (bool success, bytes memory ret) = address(operatorFilterRegistry).call(
      args
    );
    require(success, "WrappedIndexMarker: failed to update market settings");
    return ret;
  }

  function manageMarketFilterDAOSubscription(bool enable)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    address self = address(this);
    require(
      marketFilterDAOAddress != address(0),
      "WrappedIndexMarker: DAO not set"
    );
    if (!operatorFilterRegistry.isRegistered(self) && enable) {
      operatorFilterRegistry.registerAndSubscribe(self, marketFilterDAOAddress);
    } else if (enable) {
      operatorFilterRegistry.subscribe(self, marketFilterDAOAddress);
    } else {
      operatorFilterRegistry.unsubscribe(self, false);
      operatorFilterRegistry.unregister(self);
    }
  }

  /// TOMB REGISTRY ///

  function setTombContracts(
    address[] memory _contracts,
    bool[] memory _isTombContract
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      _contracts.length == _isTombContract.length,
      "IndexMarker: invalid input"
    );
    for (uint256 i = 0; i < _contracts.length; i++) {
      isTombContract[_contracts[i]] = _isTombContract[i];
    }
  }

  function setTombTokens(
    address[] memory _contracts,
    uint256[] memory _tokenIds,
    bool[] memory _isTombToken
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      _contracts.length == _tokenIds.length &&
        _tokenIds.length == _isTombToken.length,
      "IndexMarker: invalid input"
    );
    for (uint256 i = 0; i < _contracts.length; i++) {
      isSingletonTombToken[_contracts[i]][_tokenIds[i]] = _isTombToken[i];
    }
  }

  function isTomb(address _tokenContract, uint256 _tokenId)
    public
    view
    returns (bool)
  {
    return
      isTombContract[_tokenContract] ||
      isSingletonTombToken[_tokenContract][_tokenId];
  }

  /// UUPS ///

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  /// ERC165 ///

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC173).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}
