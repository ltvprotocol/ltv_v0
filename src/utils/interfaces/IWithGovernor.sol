// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IWithGovernor {
  event GovernorUpdated(address oldGovernor, address newGovernor);

  error OnlyGovernorInvalidCaller(address account);

  error OnlyGovernorOrOwnerInvalidCaller(address account);

  function governor() external view returns (address);

  function updateGovernor(address newGovernor) external;
}