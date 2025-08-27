// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IWithGuardian} from "src/timelock/utils/interfaces/IWithGuardian.sol";

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

    function updateGuardian(address newGuardian) external override onlyOwner {
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
        if (_msgSender() != owner() && _msgSender() != guardian()) {
            revert OnlyGuardianOrOwnerInvalidCaller(_msgSender());
        }
    }
}
