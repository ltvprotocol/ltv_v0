// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../../src/interfaces/ILTV.sol";

contract DeployLTVBeaconProxy is BaseScript {
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
        stateInitData.decimals = uint8(vm.envUint("DECIMALS"));
        stateInitData.collateralToken = vm.envAddress("COLLATERAL_ASSET");
        stateInitData.borrowToken = vm.envAddress("BORROW_ASSET");
        stateInitData.feeCollector = vm.envAddress("FEE_COLLECTOR");
        stateInitData.maxSafeLTVDividend = uint16(vm.envUint("MAX_SAFE_LTV_DIVIDEND"));
        stateInitData.maxSafeLTVDivider = uint16(vm.envUint("MAX_SAFE_LTV_DIVIDER"));
        stateInitData.minProfitLTVDividend = uint16(vm.envUint("MIN_PROFIT_LTV_DIVIDEND"));
        stateInitData.minProfitLTVDivider = uint16(vm.envUint("MIN_PROFIT_LTV_DIVIDER"));
        stateInitData.targetLTVDividend = uint16(vm.envUint("TARGET_LTV_DIVIDEND"));
        stateInitData.targetLTVDivider = uint16(vm.envUint("TARGET_LTV_DIVIDER"));
        stateInitData.lendingConnector = ILendingConnector(vm.envAddress("LENDING_CONNECTOR"));
        stateInitData.oracleConnector = IOracleConnector(vm.envAddress("ORACLE_CONNECTOR"));
        stateInitData.maxGrowthFeeDividend = uint16(vm.envUint("MAX_GROWTH_FEE_DIVIDEND"));
        stateInitData.maxGrowthFeeDivider = uint16(vm.envUint("MAX_GROWTH_FEE_DIVIDER"));
        stateInitData.maxTotalAssetsInUnderlying = vm.envUint("MAX_TOTAL_ASSETS_IN_UNDERLYING");
        stateInitData.slippageProvider = ISlippageProvider(vm.envAddress("SLIPPAGE_PROVIDER"));
        stateInitData.maxDeleverageFeeDividend = uint16(vm.envUint("MAX_DELEVERAGE_FEE_DIVIDEND"));
        stateInitData.maxDeleverageFeeDivider = uint16(vm.envUint("MAX_DELEVERAGE_FEE_DIVIDER"));
        stateInitData.vaultBalanceAsLendingConnector =
            ILendingConnector(vm.envAddress("VAULT_BALANCE_AS_LENDING_CONNECTOR"));
        stateInitData.owner = vm.envAddress("OWNER");
        stateInitData.guardian = vm.envAddress("GUARDIAN");
        stateInitData.governor = vm.envAddress("GOVERNOR");
        stateInitData.emergencyDeleverager = vm.envAddress("EMERGENCY_DELEVERAGER");
        stateInitData.auctionDuration = uint24(vm.envUint("AUCTION_DURATION"));
        string memory lendingConnectorName = vm.envString("LENDING_CONNECTOR_NAME");
        if (keccak256(bytes(lendingConnectorName)) == keccak256(bytes("AaveV3"))) {
            stateInitData.lendingConnectorData = abi.encode(vm.envUint("EMODE"));
        } else {
            revert("Unknown LENDING_CONNECTOR_NAME");
        }
        stateInitData.lendingConnectorData = "";

        IModules modules = IModules(vm.envAddress("MODULES_PROVIDER"));

        return abi.encodeCall(ILTV.initialize, (stateInitData, modules));
    }
}
