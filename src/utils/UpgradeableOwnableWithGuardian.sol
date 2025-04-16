// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {IWithGuardian} from './interfaces/IWithGuardian.sol';

abstract contract UpgradeableOwnableWithGuardian is OwnableUpgradeable, IWithGuardian {
    struct OwnableWithGuardian {
        address _guardian;
    }

    // keccak256("storage.UpgradeableOwnableWithGuardian")
    bytes32 private constant OwnableWithGuardianStorageLocation = 0xb60e8a6cf2c094d0527dfea44fb0b4bf02c33935fafc6f6e4cbe2a9f9dd8b0b4;

    function _getOwnableWithGuardianStorage() private pure returns (OwnableWithGuardian storage guardianStorage) {
        assembly {
            guardianStorage.slot := OwnableWithGuardianStorageLocation
        }
    }

    function __Ownable_With_Guardian_init(address initialOwner, address initialGuardian) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
        __Ownable_With_Guardian_init_unchained(initialGuardian);
    }

    function __Ownable_With_Guardian_init_unchained(address initialGuardian) internal onlyInitializing {
        _updateGuardian(initialGuardian);
    }

    modifier onlyGuardian() {
        _checkGuardian();
        _;
    }

    modifier onlyOwnerOrGuardian() {
        _checkOwnerOrGuardian();
        _;
    }

    function guardian() public view override returns (address) {
        OwnableWithGuardian storage guardianStorage = _getOwnableWithGuardianStorage();
        return guardianStorage._guardian;
    }

    function updateGuardian(address newGuardian) external override onlyOwner {
        _updateGuardian(newGuardian);
    }

    function _updateGuardian(address newGuardian) internal {
        OwnableWithGuardian storage guardianStorage = _getOwnableWithGuardianStorage();
        address oldGuardian = guardianStorage._guardian;
        guardianStorage._guardian = newGuardian;
        emit GuardianUpdated(oldGuardian, newGuardian);
    }

    function _checkGuardian() internal view {
        if (guardian() != _msgSender()) revert OnlyGuardianInvalidCaller(_msgSender());
    }

    function _checkOwnerOrGuardian() internal view {
        if (_msgSender() != owner() && _msgSender() != guardian()) revert OnlyGuardianOrOwnerInvalidCaller(_msgSender());
    }
}
