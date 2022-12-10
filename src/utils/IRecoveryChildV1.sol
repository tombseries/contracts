// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "openzeppelin-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRecoveryChildV1 is IERC165Upgradeable {
    function getRecoveryParentToken() external view returns (address, uint256);
}
