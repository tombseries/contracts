// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-upgradeable/governance/IGovernorUpgradeable.sol";

abstract contract IRecoveryGovernorV1 is IGovernorUpgradeable {
    function getRecoveryParentToken() public view virtual returns (address, uint256);
}
