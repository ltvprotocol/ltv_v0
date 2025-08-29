// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {OwnableWithGuardian} from "src/timelock/utils/OwnableWithGuardian.sol";
import {IWithPayloadsManager} from "src/timelock/utils/interfaces/IWithPayloadsManager.sol";

abstract contract WithPayloadsManager is OwnableWithGuardian, IWithPayloadsManager {
    address private _payloadsManager;

    constructor(address initialOwner, address initialGuardian, address initialPayloadsManager)
        OwnableWithGuardian(initialOwner, initialGuardian)
    {
        _updatePayloadsManager(initialPayloadsManager);
    }

    modifier onlyPayloadsManager() {
        _onlyPayloadsManager();
        _;
    }

    modifier onlyPayloadsManagerOrGuardian() {
        _onlyPayloadsManagerOrGuardian();
        _;
    }

    function _onlyPayloadsManager() internal view {
        require(_msgSender() == payloadsManager(), OnlyPayloadsManagerInvalidCaller(_msgSender()));
    }

    function _onlyPayloadsManagerOrGuardian() internal view {
        require(
            _msgSender() == payloadsManager() || _msgSender() == guardian(),
            OnlyPayloadsManagerOrOwnerInvalidCaller(_msgSender())
        );
    }

    function payloadsManager() public view override returns (address) {
        return _payloadsManager;
    }

    function updatePayloadsManager(address newPayloadsManager) external override onlyOwner {
        _updatePayloadsManager(newPayloadsManager);
    }

    function _updatePayloadsManager(address newPayloadsManager) internal {
        _payloadsManager = newPayloadsManager;
        emit PayloadsManagerUpdated(newPayloadsManager);
    }
}
