// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "openzeppelin-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
// TODO: import below from zora recovery repo
import "./IRecoveryGovernorV1.sol";

contract WrappedIndexMarker is
  Initializable,
  ERC721Upgradeable,
  AccessControlUpgradeable,
  EIP712Upgradeable,
  ERC721VotesUpgradeable,
  UUPSUpgradeable
{
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant SET_TOMB_VOTING_WEIGHT_ROLE =
    keccak256("SET_TOMB_VOTING_WEIGHT_ROLE");
  bytes32 public constant SET_TOMB_CONTRACTS_ROLE =
    keccak256("SET_TOMB_CONTRACTS_ROLE");

  IERC721MetadataUpgradeable public indexMarker;
  mapping(address => bool) public isTombContract;
  address public recoveryRegistry;
  uint16 public tombHolderVotingWeight;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _indexMarker, address _recoveryRegistry)
    public
    initializer
  {
    __ERC721_init("Wrapped Tomb Index Marker", "WMKR");
    __AccessControl_init();
    __EIP712_init("Wrapped Tomb Index Marker", "1");
    __ERC721Votes_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);
    _grantRole(SET_TOMB_VOTING_WEIGHT_ROLE, msg.sender);
    _grantRole(SET_TOMB_CONTRACTS_ROLE, msg.sender);

    indexMarker = IERC721MetadataUpgradeable(_indexMarker);
    recoveryRegistry = _recoveryRegistry;
    tombHolderVotingWeight = 1;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return indexMarker.tokenURI(tokenId);
  }

  function wrap(uint256 tokenId) public {
    indexMarker.transferFrom(msg.sender, address(this), tokenId);
    _mint(msg.sender, tokenId);
  }

  function unwrap(uint256 tokenId) public {
    require(
      ownerOf(tokenId) == msg.sender,
      "WrappedIndexMarker: caller is not owner"
    );
    _burn(tokenId);
    indexMarker.transferFrom(address(this), msg.sender, tokenId);
  }

  function _getVotingUnits(address account)
    internal
    view
    override
    returns (uint256)
  {
    (address token, uint256 tokenId) = IRecoveryGovernorV1(msg.sender)
      .getRecoveryParentToken();
    if (
      isTombContract[token] &&
      IERC721Upgradeable(token).ownerOf(tokenId) == account
    ) {
      return tombHolderVotingWeight + balanceOf(account);
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

  function setTombHolderVotingWeight(uint16 _tombHolderVotingWeight)
    public
    onlyRole(SET_TOMB_VOTING_WEIGHT_ROLE)
  {
    tombHolderVotingWeight = _tombHolderVotingWeight;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable) {
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
}
