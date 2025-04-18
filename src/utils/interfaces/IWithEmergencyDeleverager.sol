// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IWithEmergencyDeleverager {
    event EmergencyDeleveragerUpdated(address oldEmergencyDeleverager, address newEmergencyDeleverager);

    error OnlyEmergencyDeleveragerInvalidCaller(address account);

    error OnlyEmergencyDeleveragerOrOwnerInvalidCaller(address account);

    function emergencyDeleverager() external view returns (address);

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external;
}