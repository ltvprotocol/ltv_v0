// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IModules} from "../interfaces/IModules.sol";
import {IAuctionModule} from "../interfaces/reads/IAuctionModule.sol";
import {IERC20Module} from "../interfaces/reads/IERC20Module.sol";
import {ICollateralVaultModule} from "../interfaces/reads/ICollateralVaultModule.sol";
import {IBorrowVaultModule} from "../interfaces/reads/IBorrowVaultModule.sol";
import {ILowLevelRebalanceModule} from "../interfaces/reads/ILowLevelRebalanceModule.sol";
import {IInitializeModule} from "../interfaces/writes/IInitializeModule.sol";
import {ModulesState} from "../structs/state/common/ModulesState.sol";
import {IAdministrationModule} from "../interfaces/reads/IAdministrationModule.sol";
import {IModulesProviderErrors} from "../errors/IModulesProviderErrors.sol";
/**
 * @title ModulesProvider
 * @notice This contract is used to provide access to the modules of the LTV protocol.
 * It is used to get the address of the requested module.
 */

contract ModulesProvider is IModules, IModulesProviderErrors {
    // Module slot constants
    bytes32 public constant BORROW_VAULT_MODULE_SLOT = keccak256("BORROW_VAULT_MODULE");
    bytes32 public constant COLLATERAL_VAULT_MODULE_SLOT = keccak256("COLLATERAL_VAULT_MODULE");
    bytes32 public constant LOW_LEVEL_REBALANCE_MODULE_SLOT = keccak256("LOW_LEVEL_REBALANCE_MODULE");
    bytes32 public constant AUCTION_MODULE_SLOT = keccak256("AUCTION_MODULE");
    bytes32 public constant ERC20_MODULE_SLOT = keccak256("ERC20_MODULE");
    bytes32 public constant ADMINISTRATION_MODULE_SLOT = keccak256("ADMINISTRATION_MODULE");
    bytes32 public constant INITIALIZE_MODULE_SLOT = keccak256("INITIALIZE_MODULE");

    // Storage for modules
    mapping(bytes32 => address) private _modules;

    constructor(ModulesState memory state) {
        _validateModuleAddresses(state);
        _setModule(BORROW_VAULT_MODULE_SLOT, address(state.borrowVaultModule));
        _setModule(COLLATERAL_VAULT_MODULE_SLOT, address(state.collateralVaultModule));
        _setModule(LOW_LEVEL_REBALANCE_MODULE_SLOT, address(state.lowLevelRebalanceModule));
        _setModule(AUCTION_MODULE_SLOT, address(state.auctionModule));
        _setModule(ERC20_MODULE_SLOT, address(state.erc20Module));
        _setModule(ADMINISTRATION_MODULE_SLOT, address(state.administrationModule));
        _setModule(INITIALIZE_MODULE_SLOT, address(state.initializeModule));
    }

    /**
     * @dev Get the module at the given slot
     */
    function getModule(bytes32 slot) public view returns (address) {
        return _modules[slot];
    }

    /**
     * @inheritdoc IModules
     */
    function borrowVaultModule() external view override returns (IBorrowVaultModule) {
        return IBorrowVaultModule(getModule(BORROW_VAULT_MODULE_SLOT));
    }

    /**
     * @inheritdoc IModules
     */
    function collateralVaultModule() external view override returns (ICollateralVaultModule) {
        return ICollateralVaultModule(getModule(COLLATERAL_VAULT_MODULE_SLOT));
    }

    /**
     * @inheritdoc IModules
     */
    function lowLevelRebalanceModule() external view override returns (ILowLevelRebalanceModule) {
        return ILowLevelRebalanceModule(getModule(LOW_LEVEL_REBALANCE_MODULE_SLOT));
    }

    /**
     * @inheritdoc IModules
     */
    function auctionModule() external view override returns (IAuctionModule) {
        return IAuctionModule(getModule(AUCTION_MODULE_SLOT));
    }

    /**
     * @inheritdoc IModules
     */
    function erc20Module() external view override returns (IERC20Module) {
        return IERC20Module(getModule(ERC20_MODULE_SLOT));
    }

    /**
     * @inheritdoc IModules
     */
    function administrationModule() external view override returns (IAdministrationModule) {
        return IAdministrationModule(getModule(ADMINISTRATION_MODULE_SLOT));
    }

    /**
     * @inheritdoc IModules
     */
    function initializeModule() external view override returns (IInitializeModule) {
        return IInitializeModule(getModule(INITIALIZE_MODULE_SLOT));
    }

    /**
     * @dev Set the module at the given slot
     */
    function _setModule(bytes32 slot, address module) internal {
        _modules[slot] = module;
    }

    /**
     * @dev Validates that no two modules have the same address
     * @param state The modules state to validate
     */
    function _validateModuleAddresses(ModulesState memory state) internal view virtual {
        address[] memory addresses = new address[](7);

        addresses[0] = address(state.borrowVaultModule);
        addresses[1] = address(state.collateralVaultModule);
        addresses[2] = address(state.lowLevelRebalanceModule);
        addresses[3] = address(state.auctionModule);
        addresses[4] = address(state.erc20Module);
        addresses[5] = address(state.administrationModule);
        addresses[6] = address(state.initializeModule);

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i].code.length != 0, InvalidModuleAddress(addresses[i]));
            for (uint256 j = i + 1; j < addresses.length; j++) {
                require(addresses[i] != addresses[j], DuplicateModuleAddress(addresses[i]));
            }
        }
    }
}
