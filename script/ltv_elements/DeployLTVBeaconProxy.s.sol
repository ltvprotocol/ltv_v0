// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {StateInitData} from "src/structs/state/initialize/StateInitData.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {IOracleConnector} from "src/interfaces/connectors/IOracleConnector.sol";
import {ISlippageConnector} from "src/interfaces/connectors/ISlippageConnector.sol";
import {BeaconProxy} from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {GetConnectorData} from "../utils/GetConnectorData.s.sol";
import {console} from "forge-std/console.sol";

contract DeployLTVBeaconProxy is BaseScript, GetConnectorData {
    function deploy() internal override {
        address beacon = vm.envAddress("BEACON");

        BeaconProxy beaconProxy = new BeaconProxy{salt: bytes32(0)}(beacon, getInitializeFunctionCall());
        console.log("Beacon proxy deployed at: ", address(beaconProxy));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address beacon = vm.envAddress("BEACON");
        return
            keccak256(abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(beacon, getInitializeFunctionCall())));
    }

    function getInitializeFunctionCall() internal view returns (bytes memory) {
        StateInitData memory stateInitData;

        stateInitData.name = vm.envString("NAME");
        stateInitData.symbol = vm.envString("SYMBOL");
        stateInitData.collateralToken = vm.envAddress("COLLATERAL_ASSET");
        stateInitData.borrowToken = vm.envAddress("BORROW_ASSET");
        stateInitData.feeCollector = vm.envAddress("FEE_COLLECTOR");
        stateInitData.maxSafeLtvDividend = uint16(vm.envUint("MAX_SAFE_LTV_DIVIDEND"));
        stateInitData.maxSafeLtvDivider = uint16(vm.envUint("MAX_SAFE_LTV_DIVIDER"));
        stateInitData.minProfitLtvDividend = uint16(vm.envUint("MIN_PROFIT_LTV_DIVIDEND"));
        stateInitData.minProfitLtvDivider = uint16(vm.envUint("MIN_PROFIT_LTV_DIVIDER"));
        stateInitData.targetLtvDividend = uint16(vm.envUint("TARGET_LTV_DIVIDEND"));
        stateInitData.targetLtvDivider = uint16(vm.envUint("TARGET_LTV_DIVIDER"));
        stateInitData.lendingConnector = ILendingConnector(vm.envAddress("LENDING_CONNECTOR"));
        stateInitData.oracleConnector = IOracleConnector(vm.envAddress("ORACLE_CONNECTOR"));
        stateInitData.maxGrowthFeeDividend = uint16(vm.envUint("MAX_GROWTH_FEE_DIVIDEND"));
        stateInitData.maxGrowthFeeDivider = uint16(vm.envUint("MAX_GROWTH_FEE_DIVIDER"));
        stateInitData.maxTotalAssetsInUnderlying = vm.envUint("MAX_TOTAL_ASSETS_IN_UNDERLYING");
        stateInitData.slippageConnector = ISlippageConnector(vm.envAddress("SLIPPAGE_CONNECTOR"));
        stateInitData.maxDeleverageFeeDividend = uint16(vm.envUint("MAX_DELEVERAGE_FEE_DIVIDEND"));
        stateInitData.maxDeleverageFeeDivider = uint16(vm.envUint("MAX_DELEVERAGE_FEE_DIVIDER"));
        stateInitData.vaultBalanceAsLendingConnector =
            ILendingConnector(vm.envAddress("VAULT_BALANCE_AS_LENDING_CONNECTOR"));
        stateInitData.owner = vm.envAddress("OWNER");
        stateInitData.guardian = vm.envAddress("GUARDIAN");
        stateInitData.governor = vm.envAddress("GOVERNOR");
        stateInitData.emergencyDeleverager = vm.envAddress("EMERGENCY_DELEVERAGER");
        stateInitData.auctionDuration = uint24(vm.envUint("AUCTION_DURATION"));
        stateInitData.softLiquidationFeeDividend = uint16(vm.envUint("SOFT_LIQUIDATION_FEE_DIVIDEND"));
        stateInitData.softLiquidationFeeDivider = uint16(vm.envUint("SOFT_LIQUIDATION_FEE_DIVIDER"));
        stateInitData.softLiquidationLtvDividend = uint16(vm.envUint("SOFT_LIQUIDATION_LTV_DIVIDEND"));
        stateInitData.softLiquidationLtvDivider = uint16(vm.envUint("SOFT_LIQUIDATION_LTV_DIVIDER"));
        stateInitData.slippageConnectorData = getSlippageConnectorInitData();
        stateInitData.vaultBalanceAsLendingConnectorData = getVaultBalanceAsLendingConnectorInitData();
        stateInitData.lendingConnectorData = getLendingConnectorInitData();
        stateInitData.oracleConnectorData = getOracleConnectorInitData();

        return abi.encodeCall(ILTV.initialize, (stateInitData));
    }
}
