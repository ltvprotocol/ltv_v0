// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IWithPayloadsManager {
    error OnlyPayloadsManagerInvalidCaller(address account);

    error OnlyPayloadsManagerOrOwnerInvalidCaller(address account);

    event PayloadsManagerUpdated(address newPayloadsManager);

    function payloadsManager() external view returns (address);

    function updatePayloadsManager(address newPayloadsManager) external;
}
