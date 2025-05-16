// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import 'src/structs/state/ModulesState.sol';
import 'src/interfaces/IModules.sol';
import 'src/interfaces/reads/IBorrowVaultModule.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ModulesProvider is IModules, Ownable {
    // Module slot constants
    bytes32 public constant BORROW_VAULT_MODULE_SLOT = keccak256('BORROW_VAULT_MODULE');
    bytes32 public constant COLLATERAL_VAULT_MODULE_SLOT = keccak256('COLLATERAL_VAULT_MODULE');
    bytes32 public constant LOW_LEVEL_REBALANCE_MODULE_SLOT = keccak256('LOW_LEVEL_REBALANCE_MODULE');
    bytes32 public constant AUCTION_MODULE_SLOT = keccak256('AUCTION_MODULE');
    bytes32 public constant ERC20_MODULE_SLOT = keccak256('ERC20_MODULE');
    bytes32 public constant ADMINISTRATION_MODULE_SLOT = keccak256('ADMINISTRATION_MODULE');
    bytes32 public constant INITIALIZE_MODULE_SLOT = keccak256('INITIALIZE_MODULE');

    constructor(ModulesState memory state) Ownable(msg.sender) {
        _setModule(BORROW_VAULT_MODULE_SLOT, address(state.borrowVaultModule));
        _setModule(COLLATERAL_VAULT_MODULE_SLOT, address(state.collateralVaultModule));
        _setModule(LOW_LEVEL_REBALANCE_MODULE_SLOT, address(state.lowLevelRebalanceModule));
        _setModule(AUCTION_MODULE_SLOT, address(state.auctionModule));
        _setModule(ERC20_MODULE_SLOT, address(state.erc20Module));
        _setModule(ADMINISTRATION_MODULE_SLOT, address(state.administrationModule));
        _setModule(INITIALIZE_MODULE_SLOT, state.initializeModule);
    }

    // Storage for modules
    mapping(bytes32 => address) private _modules;

    function setModule(bytes32 slot, address module) external onlyOwner {
        _setModule(slot, module);
    }

    function _setModule(bytes32 slot, address module) internal {
        _modules[slot] = module;
    }

    function getModule(bytes32 slot) public view returns (address) {
        return _modules[slot];
    }

    // IModules interface implementation
    function borrowVaultModule() external view override returns (IBorrowVaultModule) {
        return IBorrowVaultModule(getModule(BORROW_VAULT_MODULE_SLOT));
    }

    function collateralVaultModule() external view override returns (ICollateralVault) {
        return ICollateralVault(getModule(COLLATERAL_VAULT_MODULE_SLOT));
    }

    function lowLevelRebalanceModule() external view override returns (ILowLevelRebalance) {
        return ILowLevelRebalance(getModule(LOW_LEVEL_REBALANCE_MODULE_SLOT));
    }

    function auctionModule() external view override returns (IAuction) {
        return IAuction(getModule(AUCTION_MODULE_SLOT));
    }

    function erc20Module() external view override returns (IERC20Read) {
        return IERC20Read(getModule(ERC20_MODULE_SLOT));
    }

    function administrationModule() external view override returns (IAdministration) {
        return IAdministration(getModule(ADMINISTRATION_MODULE_SLOT));
    }

    function initializeModule() external view override returns (address) {
        return getModule(INITIALIZE_MODULE_SLOT);
    }
}
