// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {IWithEmergencyDeleverager} from './interfaces/IWithEmergencyDeleverager.sol';

abstract contract UpgradeableOwnableWithEmergencyDeleverager is OwnableUpgradeable, IWithEmergencyDeleverager {
    struct OwnableWithEmergencyDeleverager {
        address _emergencyDeleverager;
    }

    // keccak256("storage.UpgradeableOwnableWithEmergencyDeleverager")
    bytes32 private constant OwnableWithEmergencyDeleveragerStorageLocation = 0x46798bb8057efc5a1d6baf4083b6bd07e15b2aa35542d5edffc59f448755677f;

    function _getOwnableWithEmergencyDeleveragerStorage() private pure returns (OwnableWithEmergencyDeleverager storage emergencyDeleveragerStorage) {
        assembly {
            emergencyDeleveragerStorage.slot := OwnableWithEmergencyDeleveragerStorageLocation
        }
    }

    function __Ownable_With_EmergencyDeleverager_init(address initialOwner, address initialEmergencyDeleverager) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
        __Ownable_With_EmergencyDeleverager_init_unchained(initialEmergencyDeleverager);
    }

    function __Ownable_With_EmergencyDeleverager_init_unchained(address initialEmergencyDeleverager) internal onlyInitializing {
        _updateEmergencyDeleverager(initialEmergencyDeleverager);
    }

    modifier onlyEmergencyDeleverager() {
        _checkEmergencyDeleverager();
        _;
    }

    modifier onlyOwnerOrEmergencyDeleverager() {
        _checkOwnerOrEmergencyDeleverager();
        _;
    }

    function emergencyDeleverager() public view override returns (address) {
        OwnableWithEmergencyDeleverager storage emergencyDeleveragerStorage = _getOwnableWithEmergencyDeleveragerStorage();
        return emergencyDeleveragerStorage._emergencyDeleverager;
    }

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external override onlyOwner {
        _updateEmergencyDeleverager(newEmergencyDeleverager);
    }

    function _updateEmergencyDeleverager(address newEmergencyDeleverager) internal {
        OwnableWithEmergencyDeleverager storage emergencyDeleveragerStorage = _getOwnableWithEmergencyDeleveragerStorage();
        address oldEmergencyDeleverager = emergencyDeleveragerStorage._emergencyDeleverager;
        emergencyDeleveragerStorage._emergencyDeleverager = newEmergencyDeleverager;
        emit EmergencyDeleveragerUpdated(oldEmergencyDeleverager, newEmergencyDeleverager);
    }

    function _checkEmergencyDeleverager() internal view {
        if (emergencyDeleverager() != _msgSender()) revert OnlyEmergencyDeleveragerInvalidCaller(_msgSender());
    }

    function _checkOwnerOrEmergencyDeleverager() internal view {
        if (_msgSender() != owner() && _msgSender() != emergencyDeleverager()) revert OnlyEmergencyDeleveragerOrOwnerInvalidCaller(_msgSender());
    }
}
