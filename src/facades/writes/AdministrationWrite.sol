// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";
import "../writes/CommonWrite.sol";

abstract contract AdministrationWrite is LTVState, CommonWrite {
    function setTargetLTV(uint128 value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setMaxSafeLTV(uint128 value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setMinProfitLTV(uint128 value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setFeeCollector(address _feeCollector) external {
        _delegate(modules.administrationWrite(), abi.encode(_feeCollector));
    }

    function setMaxTotalAssetsInUnderlying(uint256 _maxTotalAssetsInUnderlying) external {
        _delegate(modules.administrationWrite(), abi.encode(_maxTotalAssetsInUnderlying));
    }

    function setMaxDeleverageFee(uint256 value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setIsWhitelistActivated(bool activate) external {
        _delegate(modules.administrationWrite(), abi.encode(activate));
    }

    function setWhitelistRegistry(address value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setSlippageProvider(address _slippageProvider) external {
        _delegate(modules.administrationWrite(), abi.encode(_slippageProvider));
    }

    function allowDisableFunctions(bytes4[] memory signatures, bool isDisabled) external {
        _delegate(modules.administrationWrite(), abi.encode(signatures, isDisabled));
    }

    function setIsDepositDisabled(bool value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setIsWithdrawDisabled(bool value) external {
        _delegate(modules.administrationWrite(), abi.encode(value));
    }

    function setLendingConnector(address _lendingConnector) external {
        _delegate(modules.administrationWrite(), abi.encode(_lendingConnector));
    }

    function setOracleConnector(address _oracleConnector) external {
        _delegate(modules.administrationWrite(), abi.encode(_oracleConnector));
    }

    function deleverageAndWithdraw(uint256 closeAmountBorrow, uint256 deleverageFee) external {
        _delegate(modules.administrationWrite(), abi.encode(closeAmountBorrow, deleverageFee));
    }

    function updateEmergencyDeleverager(address newEmergencyDeleverager) external {
        _delegate(modules.administrationWrite(), abi.encode(newEmergencyDeleverager));
    }

    function updateOwner(address newOwner) external {
        _delegate(modules.administrationWrite(), abi.encode(newOwner));
    }

    function updateGuardian(address newGuardian) external {
        _delegate(modules.administrationWrite(), abi.encode(newGuardian));
    }

    function updateGovernor(address newGovernor) external {
        _delegate(modules.administrationWrite(), abi.encode(newGovernor));
    }
}
