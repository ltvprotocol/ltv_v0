// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {IWithGovernor} from './interfaces/IWithGovernor.sol';

abstract contract UpgradeableOwnableWithGovernor is OwnableUpgradeable, IWithGovernor {
    struct OwnableWithGovernor {
        address _governor;
    }

    // keccak256("storage.UpgradeableOwnableWithGovernor")
    bytes32 private constant OwnableWithGovernorStorageLocation = 0xda3ee8bcb5d3050b69493a59eb63b65657bdfb51032a8d53879973fe01319f9c;

    function _getOwnableWithGovernorStorage() private pure returns (OwnableWithGovernor storage governorStorage) {
        assembly {
            governorStorage.slot := OwnableWithGovernorStorageLocation
        }
    }

    function __Ownable_With_Governor_init(address initialOwner, address initialGovernor) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
        __Ownable_With_Governor_init_unchained(initialGovernor);
    }

    function __Ownable_With_Governor_init_unchained(address initialGovernor) internal onlyInitializing {
        _updateGovernor(initialGovernor);
    }

    modifier onlyGovernor() {
        _checkGovernor();
        _;
    }

    modifier onlyOwnerOrGovernor() {
        _checkOwnerOrGovernor();
        _;
    }

    function governor() public view override returns (address) {
        OwnableWithGovernor storage governorStorage = _getOwnableWithGovernorStorage();
        return governorStorage._governor;
    }

    function updateGovernor(address newGovernor) external override onlyOwnerOrGovernor {
        _updateGovernor(newGovernor);
    }

    function _updateGovernor(address newGovernor) internal {
        OwnableWithGovernor storage governorStorage = _getOwnableWithGovernorStorage();
        address oldGovernor = governorStorage._governor;
        governorStorage._governor = newGovernor;
        emit GovernorUpdated(oldGovernor, newGovernor);
    }

    function _checkGovernor() internal view {
        if (governor() != _msgSender()) revert OnlyGovernorInvalidCaller(_msgSender());
    }

    function _checkOwnerOrGovernor() internal view {
        if (_msgSender() != owner() && _msgSender() != governor()) revert OnlyGovernorOrOwnerInvalidCaller(_msgSender());
    }
}
