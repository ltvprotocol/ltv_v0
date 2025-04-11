// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IWithGuardian} from './interfaces/IWithGuardian.sol';

abstract contract OwnableWithGuardian is Ownable, IWithGuardian {
    address private _guardian;

    constructor(address initialOwner, address initialGuardian) Ownable(initialOwner) {
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
        return _guardian;
    }

    function updateGuardian(address newGuardian) external override onlyOwnerOrGuardian {
        _updateGuardian(newGuardian);
    }

    function _updateGuardian(address newGuardian) internal {
        address oldGuardian = _guardian;
        _guardian = newGuardian;
        emit GuardianUpdated(oldGuardian, newGuardian);
    }

    function _checkGuardian() internal view {
        if (guardian() != _msgSender()) revert OnlyGuardianInvalidCaller(_msgSender());
    }

    function _checkOwnerOrGuardian() internal view {
        if (_msgSender() != owner() && _msgSender() != guardian()) revert OnlyGuardianOrOwnerInvalidCaller(_msgSender());
    }
}
