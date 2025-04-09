// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';

abstract contract UpgradeableOwnableWithGovernor is OwnableUpgradeable {
    error OnlyGovernorInvalidCaller(address caller);
    error OnlyGovernorOrOwnerInvalidCaller(address caller);
    event GovernorUpdated(address indexed oldGovernor, address indexed newGovernor);

    struct OwnableWithGovernor {
        address _governor;
    }

    // keccak256("storage.UpgradeableOwnableWithGovernor")
    bytes32 private constant OwnableWithGovernorStorageLocation = 0xda3ee8bcb5d3050b69493a59eb63b65657bdfb51032a8d53879973fe01319f9c;

    function _getOwnableWithGovernorStorage() private pure returns (OwnableWithGovernor storage $) {
        assembly {
            $.slot := OwnableWithGovernorStorageLocation
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

    function governor() public view returns (address) {
        OwnableWithGovernor storage $ = _getOwnableWithGovernorStorage();
        return $._governor;
    }

    function updateGovernor(address newGovernor) external onlyOwnerOrGovernor {
        _updateGovernor(newGovernor);
    }

    function _updateGovernor(address newGovernor) internal {
        OwnableWithGovernor storage $ = _getOwnableWithGovernorStorage();
        address oldGovernor = $._governor;
        $._governor = newGovernor;
        emit GovernorUpdated(oldGovernor, newGovernor);
    }

    function _checkGovernor() internal view {
        if (governor() != _msgSender()) revert OnlyGovernorInvalidCaller(_msgSender());
    }

    function _checkOwnerOrGovernor() internal view {
        if (_msgSender() != owner() && _msgSender() != governor()) revert OnlyGovernorOrOwnerInvalidCaller(_msgSender());
    }
}
