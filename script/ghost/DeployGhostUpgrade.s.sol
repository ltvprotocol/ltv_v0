// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {ILTV} from "../../src/interfaces/ILTV.sol";
import {LTVState} from "../../src/states/LTVState.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ITransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IModules} from "../../src/interfaces/IModules.sol";
import {ISlippageProvider} from "../../src/interfaces/ISlippageProvider.sol";
import {ILendingConnector} from "../../src/interfaces/ILendingConnector.sol";
import {IOracleConnector} from "../../src/interfaces/IOracleConnector.sol";

import {StdCheats} from "forge-std/StdCheats.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {ILTV} from "../../src/interfaces/ILTV.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm} from "forge-std/Vm.sol";

function getHolders(Vm vm) view returns (address[] memory) {
    // Reads holders from data/holders.json using stdJson
    string memory path = "script/ghost/data/holders.json";
    // forge-lint: disable-next-line
    string memory json = vm.readFile(path);
    address[] memory holders = abi.decode(vm.parseJson(json), (address[]));
    return holders;
}

struct ApprovalData {
    address owner;
    address spender;
    uint256 amount;
}

struct OldStateBackup {
    address feeCollector;
    int256 futureBorrowAssets;
    int256 futureCollateralAssets;
    int256 futureRewardBorrowAssets;
    int256 futureRewardCollateralAssets;
    uint256 startAuction;
    // ERC 20 state
    uint256 baseTotalSupply;
    string name;
    string symbol;
    uint8 decimals;
    address collateralToken;
    address borrowToken;
    uint256 lastSeenTokenPrice;
    uint256 maxTotalAssetsInUnderlying;
    address[] holders;
    uint256[] balances;
}

struct NewFields {
    address vaultBalanceAsLendingConnector;
    address slippageProvider;
    address governor;
    address guardian;
    address emergencyDeleverager;
    address modules;
    address lendingConnector;
    address oracleConnector;
    uint24 auctionDuration;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint16 maxDeleverageFeeDividend;
    uint16 maxDeleverageFeeDivider;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
    uint16 targetLtvDividend;
    uint16 targetLtvDivider;
    uint8 boolSlot;
    uint256 collateralSlippage;
    uint256 borrowSlippage;
    ApprovalData[] allowances;
}

abstract contract OldState {
    address public feeCollector;

    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;
    uint256 public startAuction;

    // ERC 20 state
    uint256 public baseTotalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint128 public maxSafeLtv;
    uint128 public minProfitLtv;
    uint128 public targetLtv;

    ILendingConnector public lendingConnector;
    IOracleConnector public oracleConnector;

    uint256 internal lastSeenTokenPrice;
    uint256 internal maxGrowthFee;

    uint256 public maxTotalAssetsInUnderlying;

    mapping(bytes4 => bool) public _isFunctionDisabled;
}

error Mismatch(uint256, uint256);

contract OldStateCleaner is OldState {
    function cleanAndBackup(ApprovalData[] memory allowances, address[] memory holders)
        public
        returns (OldStateBackup memory)
    {
        OldStateBackup memory backup;
        backup.feeCollector = feeCollector;
        delete feeCollector;
        backup.futureBorrowAssets = futureBorrowAssets;
        delete futureBorrowAssets;
        backup.futureCollateralAssets = futureCollateralAssets;
        delete futureCollateralAssets;
        backup.futureRewardBorrowAssets = futureRewardBorrowAssets;
        delete futureRewardBorrowAssets;
        backup.futureRewardCollateralAssets = futureRewardCollateralAssets;
        delete futureRewardCollateralAssets;
        backup.startAuction = startAuction;
        delete startAuction;
        backup.baseTotalSupply = baseTotalSupply;
        delete baseTotalSupply;
        backup.name = name;
        delete name;
        backup.symbol = symbol;
        delete symbol;
        backup.decimals = decimals;
        delete decimals;
        backup.collateralToken = address(collateralToken);
        delete collateralToken;
        backup.borrowToken = address(borrowToken);
        delete borrowToken;
        delete maxSafeLtv;
        delete minProfitLtv;
        delete targetLtv;
        delete lendingConnector;
        delete oracleConnector;
        backup.lastSeenTokenPrice = lastSeenTokenPrice;
        delete lastSeenTokenPrice;
        delete maxGrowthFee;
        backup.maxTotalAssetsInUnderlying = maxTotalAssetsInUnderlying;
        delete maxTotalAssetsInUnderlying;
        backup.balances = new uint256[](holders.length);
        backup.holders = holders;
        uint256 holdersBalance;
        for (uint256 i = 0; i < holders.length; i++) {
            backup.balances[i] = balanceOf[holders[i]];
            delete balanceOf[holders[i]]; // TODO: check if this is correct
            holdersBalance += backup.balances[i];
        }
        for (uint256 i = 0; i < allowances.length; i++) {
            delete allowance[allowances[i].owner][allowances[i].spender];
        }
        require(backup.baseTotalSupply == holdersBalance, Mismatch(backup.baseTotalSupply, holdersBalance));
        return backup;
    }
}

contract NewStateRemapper is LTVState {
    function remapState(OldStateBackup calldata oldState, NewFields calldata newFields) public {
        feeCollector = oldState.feeCollector;
        futureBorrowAssets = oldState.futureBorrowAssets;
        futureCollateralAssets = oldState.futureCollateralAssets;
        futureRewardBorrowAssets = oldState.futureRewardBorrowAssets;
        futureRewardCollateralAssets = oldState.futureRewardCollateralAssets;
        startAuction = uint56(oldState.startAuction);
        baseTotalSupply = oldState.baseTotalSupply;
        name = oldState.name;
        symbol = oldState.symbol;
        decimals = oldState.decimals;
        collateralToken = IERC20(oldState.collateralToken);
        borrowToken = IERC20(oldState.borrowToken);
        lendingConnector = ILendingConnector(newFields.lendingConnector);
        lastSeenTokenPrice = oldState.lastSeenTokenPrice;
        maxTotalAssetsInUnderlying = oldState.maxTotalAssetsInUnderlying;
        uint256 holdersBalance;
        for (uint256 i = 0; i < oldState.holders.length; i++) {
            balanceOf[oldState.holders[i]] = oldState.balances[i];
            holdersBalance += oldState.balances[i];
        }
        require(baseTotalSupply == holdersBalance, Mismatch(baseTotalSupply, holdersBalance));
        vaultBalanceAsLendingConnector = ILendingConnector(newFields.vaultBalanceAsLendingConnector);
        oracleConnector = IOracleConnector(newFields.oracleConnector);
        (bool success,) = address(oracleConnector).delegatecall(
            abi.encodeCall(IOracleConnector.initializeOracleConnectorData, (bytes("")))
        );
        require(success);
        slippageProvider = ISlippageProvider(newFields.slippageProvider);
        (success,) = address(slippageProvider).delegatecall(
            abi.encodeCall(
                ISlippageProvider.initializeSlippageProviderData,
                (abi.encode(newFields.collateralSlippage, newFields.borrowSlippage))
            )
        );
        require(success);

        modules = IModules(newFields.modules);
        governor = newFields.governor;
        guardian = newFields.guardian;
        emergencyDeleverager = newFields.emergencyDeleverager;
        auctionDuration = newFields.auctionDuration;
        maxGrowthFeeDividend = newFields.maxGrowthFeeDividend;
        maxGrowthFeeDivider = newFields.maxGrowthFeeDivider;
        maxDeleverageFeeDividend = newFields.maxDeleverageFeeDividend;
        maxDeleverageFeeDivider = newFields.maxDeleverageFeeDivider;
        maxSafeLtvDividend = newFields.maxSafeLtvDividend;
        maxSafeLtvDivider = newFields.maxSafeLtvDivider;
        minProfitLtvDividend = newFields.minProfitLtvDividend;
        minProfitLtvDivider = newFields.minProfitLtvDivider;
        targetLtvDividend = newFields.targetLtvDividend;
        targetLtvDivider = newFields.targetLtvDivider;
        boolSlot = newFields.boolSlot;
        for (uint256 i = 0; i < newFields.allowances.length; i++) {
            allowance[newFields.allowances[i].owner][newFields.allowances[i].spender] = newFields.allowances[i].amount;
        }
    }
}

contract Upgrader is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function execute(address addr, bytes memory data) public onlyOwner {
        (bool success,) = addr.call(data);
        require(success, "Failed to execute");
    }

    function executeDelegateCall(address addr, bytes memory data) public onlyOwner {
        (bool success,) = addr.delegatecall(data);
        require(success, "Failed to execute");
    }

    function upgrade(
        address proxy,
        address _proxyAdmin,
        address newImplementation,
        address newProxyAdminOwner,
        NewFields calldata newFields,
        address[] calldata holders
    ) public {
        ProxyAdmin proxyAdmin = ProxyAdmin(_proxyAdmin);
        OldStateCleaner oldStateCleaner = new OldStateCleaner();
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), address(oldStateCleaner), "");
        OldStateBackup memory oldState = OldStateCleaner(proxy).cleanAndBackup(newFields.allowances, holders);
        NewStateRemapper newStateRemapper = new NewStateRemapper();
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), address(newStateRemapper), "");
        NewStateRemapper(proxy).remapState(oldState, newFields);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImplementation, "");
        proxyAdmin.transferOwnership(newProxyAdminOwner);
    }
}

struct JsonStruct {
    address address_;
    bytes32 blockHash;
    bytes blockNumber;
    bytes32 data;
    bytes logIndex;
    bool removed;
    bytes32[] topics;
    bytes32 transactionHash;
    bytes transactionIndex;
}

contract DeployGhostUpgrade is Script, StdCheats, StdAssertions {
    using stdJson for string;

    function getApprovalLogs() internal view returns (ApprovalData[] memory) {
        // forge-lint: disable-next-line
        string memory json = vm.readFile("script/ghost/data/allowance_logs.json");
        // Count number of entries
        JsonStruct[] memory jsonStructs = abi.decode(vm.parseJson(json), (JsonStruct[]));
        ApprovalData[] memory approvals = new ApprovalData[](jsonStructs.length);

        for (uint256 i = 0; i < jsonStructs.length; i++) {
            // Parse topics
            bytes32 ownerTopic = jsonStructs[i].topics[1];
            bytes32 spenderTopic = jsonStructs[i].topics[2];
            bytes32 data = jsonStructs[i].data;
            approvals[i] = ApprovalData({
                owner: address(uint160(uint256(ownerTopic))),
                spender: address(uint160(uint256(spenderTopic))),
                amount: uint256(data)
            });
        }
        return approvals;
    }

    function run() public {
        address proxy = vm.envAddress("PROXY");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        address ltv = vm.envAddress("LTV");
        ApprovalData[] memory allowances = getApprovalLogs();
        NewFields memory newFields = NewFields({
            vaultBalanceAsLendingConnector: vm.envAddress("VAULT_BALANCE_AS_LENDING_CONNECTOR"),
            slippageProvider: vm.envAddress("SLIPPAGE_CONNECTOR"),
            governor: vm.envAddress("GOVERNOR"),
            guardian: vm.envAddress("GUARDIAN"),
            emergencyDeleverager: vm.envAddress("EMERGENCY_DELEVERAGER"),
            modules: vm.envAddress("MODULES_PROVIDER"),
            lendingConnector: vm.envAddress("LENDING_CONNECTOR"),
            oracleConnector: vm.envAddress("ORACLE_CONNECTOR"),
            auctionDuration: 1000,
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 50,
            maxSafeLtvDividend: 9,
            maxSafeLtvDivider: 10,
            minProfitLtvDividend: 5,
            minProfitLtvDivider: 10,
            targetLtvDividend: 75,
            targetLtvDivider: 100,
            boolSlot: 0,
            collateralSlippage: vm.envUint("COLLATERAL_SLIPPAGE"),
            borrowSlippage: vm.envUint("BORROW_SLIPPAGE"),
            allowances: allowances
        });
        address[] memory holders = getHolders(vm);
        // vm.startBroadcast();
        vm.startPrank(msg.sender);
        Upgrader upgrader = new Upgrader{salt: bytes32(0)}(msg.sender);

        vm.store(proxyAdmin, 0, bytes32(uint256(uint160(msg.sender))));

        ProxyAdmin(proxyAdmin).transferOwnership(address(upgrader));
        upgrader.upgrade(proxy, proxyAdmin, ltv, msg.sender, newFields, holders);
        // vm.stopBroadcast();
        vm.stopPrank();

        // test part
        ILTV _ltv = ILTV(vm.envAddress("PROXY"));
        address collateralToken = _ltv.collateralToken();
        address random = makeAddr("random");
        vm.startPrank(random);
        deal(collateralToken, random, type(uint256).max);
        IERC20(collateralToken).approve(address(_ltv), type(uint256).max);
        _ltv.executeLowLevelRebalanceCollateralHint(10 ** 18, true);

        address borrowToken = _ltv.borrowToken();
        _ltv.withdraw(_ltv.maxWithdraw(random), random, random);
        assertGt(IERC20(borrowToken).balanceOf(random), 0);
        assertGt(_ltv.balanceOf(random), 0);
        assertGt(
            _ltv.allowance(0xbd6158Bc84546E235dc8CB62fD6a98De2f7B17bF, 0xE2A7f267124AC3E4131f27b9159c78C521A44F3c), 0
        );
    }
}
