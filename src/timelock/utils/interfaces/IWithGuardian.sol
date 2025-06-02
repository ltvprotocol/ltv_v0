// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IWithGuardian {
    event GuardianUpdated(address oldGuardian, address newGuardian);

    error OnlyGuardianInvalidCaller(address account);

    error OnlyGuardianOrOwnerInvalidCaller(address account);

    function guardian() external view returns (address);

    function updateGuardian(address newGuardian) external;
}
