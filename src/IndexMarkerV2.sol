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
import "zora-drops-contracts/interfaces/IOperatorFilterRegistry.sol";
import "./IRecoveryChildV1.sol";
import "./utils/IERC173.sol";

/**
 * note: This contract uses role-based access control. it also has an IERC173
 * compliant Owner, but this is solely for opensea royalty compatibility. The
 * Owner is the openseaRoyaltiesManager, which is set by whoever has the
 * OPENSEA_ROYALTIES_ADMIN_ROLE. The openseaRoyaltiesManager must be a
 * trusted EOA (not a contract), but the OPENSEA_ROYALTIES_ADMIN_ROLE should
 * be a multisig or governance contract.
 */

contract IndexMarkerV2 is
  Initializable,
  ERC721Upgradeable,
  AccessControlUpgradeable,
  EIP712Upgradeable,
  ERC721VotesUpgradeable,
  ERC2981Upgradeable,
  UUPSUpgradeable,
  IERC173 /* required for opensea royalties */
{
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant SET_TOMB_VOTING_WEIGHT_ROLE =
    keccak256("SET_TOMB_VOTING_WEIGHT_ROLE");
  bytes32 public constant SET_TOMB_CONTRACTS_ROLE =
    keccak256("SET_TOMB_CONTRACTS_ROLE");
  bytes32 public constant SET_ROYALTIES_ROLE = keccak256("SET_ROYALTIES_ROLE");
  bytes32 public constant UPDATE_MARKET_SETTINGS_ROLE =
    keccak256("UPDATE_MARKET_SETTINGS_ROLE");
  bytes32 public constant OPENSEA_ROYALTIES_ADMIN_ROLE =
    keccak256("OPENSEA_ROYALTIES_ADMIN_ROLE");

  uint16 internal constant DEFAULT_TOMB_HOLDER_VOTING_WEIGHT = 30; // 30 votes
  uint96 internal constant DEFAULT_ROYALTY_BPS = 1_000; // 10%
  address payable internal constant TOMB_ARTIST =
    payable(0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46);

  // zora & opensea compatibility
  IOperatorFilterRegistry immutable operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
  address public marketFilterDAOAddress;

  uint96 public royaltyBps;
  IERC721MetadataUpgradeable public indexMarker;
  mapping(address => bool) public isTombContract;
  mapping(address => mapping(uint256 => bool)) public isSingletonTombToken;
  uint16 public tombHolderVotingWeight;
  address internal openseaRoyaltiesManager;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _indexMarker,
    address payable _royaltyDestination,
    address _marketFilterDAOAddress
  ) public initializer {
    __ERC721_init("Wrapped Tomb Index Marker", "WMKR");
    __AccessControl_init();
    __EIP712_init("Wrapped Tomb Index Marker", "1");
    __ERC721Votes_init();
    __UUPSUpgradeable_init();
    __ERC2981_init();

    indexMarker = IERC721MetadataUpgradeable(_indexMarker);
    marketFilterDAOAddress = _marketFilterDAOAddress;
    tombHolderVotingWeight = DEFAULT_TOMB_HOLDER_VOTING_WEIGHT;
    royaltyBps = DEFAULT_ROYALTY_BPS;

    // uncomment below if we allow tokenId 0 to mint
    /* isSingletonTombToken[_indexMarker][0] = true;
    _setTokenRoyalty(0, TOMB_ARTIST, royaltyBps); */

    _setDefaultRoyalty(_royaltyDestination, royaltyBps);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    openseaRoyaltiesManager = msg.sender;
    _grantRole(OPENSEA_ROYALTIES_ADMIN_ROLE, msg.sender);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return indexMarker.tokenURI(tokenId);
  }

  function mint(uint256 tokenId) public {
    // remove requirement below to allow tokenId 0 to mint
    require(
      tokenId != 0,
      "WrappedIndexMarker: tokenId 0 is not an Index Marker"
    );

    indexMarker.transferFrom(msg.sender, address(this), tokenId);
    _mint(msg.sender, tokenId);
  }

  function _getVotingUnits(address account)
    internal
    view
    override
    returns (uint256)
  {
    if (
      IERC165Upgradeable(msg.sender).supportsInterface(
        type(IRecoveryChildV1).interfaceId
      )
    ) {
      (address parentToken, uint256 parentTokenId) = IRecoveryChildV1(
        msg.sender
      ).getRecoveryParentToken();
      if (
        isTomb(parentToken, parentTokenId) &&
        IERC721Upgradeable(parentToken).ownerOf(parentTokenId) == account
      ) {
        return tombHolderVotingWeight + balanceOf(account);
      }
    }
    return balanceOf(account);
  }

  function setTombContracts(
    address[] memory _contracts,
    bool[] memory _isTombContract
  ) public onlyRole(SET_TOMB_CONTRACTS_ROLE) {
    require(
      _contracts.length == _isTombContract.length,
      "WrappedIndexMarker: invalid input"
    );
    for (uint256 i = 0; i < _contracts.length; i++) {
      isTombContract[_contracts[i]] = _isTombContract[i];
    }
  }

  function setTombTokens(
    address[] memory _contracts,
    uint256[] memory _tokenIds,
    bool[] memory _isTombToken
  ) public onlyRole(SET_TOMB_CONTRACTS_ROLE) {
    require(
      _contracts.length == _tokenIds.length &&
        _tokenIds.length == _isTombToken.length,
      "WrappedIndexMarker: invalid input"
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

  function setTombHolderVotingWeight(uint16 _tombHolderVotingWeight)
    public
    onlyRole(SET_TOMB_VOTING_WEIGHT_ROLE)
  {
    tombHolderVotingWeight = _tombHolderVotingWeight;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    public
    onlyRole(SET_ROYALTIES_ROLE)
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() public onlyRole(SET_ROYALTIES_ROLE) {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) public onlyRole(SET_ROYALTIES_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function resetTokenRoyalty(uint256 tokenId)
    public
    onlyRole(SET_ROYALTIES_ROLE)
  {
    _resetTokenRoyalty(tokenId);
  }

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

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable) {
    // for opensea royalties
    if (from != msg.sender && address(operatorFilterRegistry).code.length > 0) {
      require(
        operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender),
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

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADER_ROLE)
  {}

  // for opensea royalties
  function transferOwnership(address _newManager)
    public
    onlyRole(OPENSEA_ROYALTIES_ADMIN_ROLE)
  {
    emit OwnershipTransferred(openseaRoyaltiesManager, _newManager);
    openseaRoyaltiesManager = _newManager;
  }

  // for opensea royalties
  function owner() external view returns (address) {
    return openseaRoyaltiesManager;
  }

  // for zora & opensea royalty integration
  function updateMarketFilterSettings(bytes calldata args)
    external
    onlyRole(UPDATE_MARKET_SETTINGS_ROLE)
    returns (bytes memory)
  {
    (bool success, bytes memory ret) = address(operatorFilterRegistry).call(
      args
    );
    require(success, "WrappedIndexMarker: failed to update market settings");
    return ret;
  }

  // for zora & opensea royalty integration
  function manageMarketFilterDAOSubscription(bool enable)
    external
    onlyRole(UPDATE_MARKET_SETTINGS_ROLE)
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
}
