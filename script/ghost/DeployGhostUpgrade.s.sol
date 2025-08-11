// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../../src/interfaces/ILTV.sol";
import "../../src/states/LTVState.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/events/IERC20Events.sol";
import "forge-std/Vm.sol";

import "forge-std/StdCheats.sol";
import "forge-std/StdAssertions.sol";
import "../../src/interfaces/ILTV.sol";

function getHolders() pure returns (address[19] memory) {
    return [
        0xC185CDED750dc34D1b289355Fe62d10e86BEDDee,
        0x9Cf35beA12F0bA72528C43Ba96aE6979D5A63e75,
        0x16A69E7BD9000D5E8EF128D5D5A803f8F4F94980,
        0x3d2fDf8375e5BCDf2491fE34d80c462931144D4c,
        0xC35EcD12416db6c227C47b8218F8745abB35B421,
        0x6cA89411A3737402df1B2FF44Eda7Fb23226F42f,
        0xa95584c820B5BC990A0572dF4FAbA7FB9F4E210b,
        0xdE3ad03873Db3eEC89cdEAB5b9D72317c6a4F410,
        0x82c0BD9c20379ae7d08Bd74BD7Afb2a18c6dBd43,
        0x6E5019C712827b5e7D30e1AdA52B871582ca4349,
        0x567Ed3AA2886a8859A62C88b3F9b35d2c9991cf6,
        0xbd6158Bc84546E235dc8CB62fD6a98De2f7B17bF,
        0x55db83794dc824145b196da043B3e74979Fb4F11,
        0xdaa1AfB876F226fd95e54a75C1218459E13A951A,
        0x83ea7E989E46cBbc08e05745297aBFFb18Df2820,
        0x87B3C9726f150f0B8f3b9fEEc5ACbE28eb5160bB,
        0xDec0de987DB64aDbE297daC3762178A1b103014E,
        0xA9FbD3dea591433624F29D01FE47Ad1E6F25ad48,
        0x4d0072045BFaE4A76Fe16F4e1F3c6ca6Ac8709Ab
    ];
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
    IOracleConnector oracleConnector;
    uint256 lastSeenTokenPrice;
    uint256 maxTotalAssetsInUnderlying;
    uint256[19] balances;
}

struct NewFields {
    address vaultBalanceAsLendingConnector;
    address slippageProvider;
    address governor;
    address guardian;
    address emergencyDeleverager;
    address modules;
    address lendingConnector;
    uint24 auctionDuration;
    uint16 maxGrowthFeeDividend;
    uint16 maxGrowthFeeDivider;
    uint16 maxDeleverageFeeDividend;
    uint16 maxDeleverageFeeDivider;
    uint16 maxSafeLTVDividend;
    uint16 maxSafeLTVDivider;
    uint16 minProfitLTVDividend;
    uint16 minProfitLTVDivider;
    uint16 targetLTVDividend;
    uint16 targetLTVDivider;
    uint8 boolSlot;
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

    uint128 public maxSafeLTV;
    uint128 public minProfitLTV;
    uint128 public targetLTV;

    ILendingConnector public lendingConnector;
    IOracleConnector public oracleConnector;

    uint256 internal lastSeenTokenPrice;
    uint256 internal maxGrowthFee;

    uint256 public maxTotalAssetsInUnderlying;

    mapping(bytes4 => bool) public _isFunctionDisabled;
}

error Mismatch(uint256, uint256);

contract OldStateCleaner is OldState {
    function cleanAndBackup(ApprovalData[] memory allowances) public returns (OldStateBackup memory) {
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
        delete maxSafeLTV;
        delete minProfitLTV;
        delete targetLTV;
        delete lendingConnector;
        backup.oracleConnector = oracleConnector;
        delete oracleConnector;
        backup.lastSeenTokenPrice = lastSeenTokenPrice;
        delete lastSeenTokenPrice;
        delete maxGrowthFee;
        backup.maxTotalAssetsInUnderlying = maxTotalAssetsInUnderlying;
        delete maxTotalAssetsInUnderlying;
        address[19] memory holders = getHolders();
        uint256 holdersBalance;
        for (uint256 i = 0; i < 19; i++) {
            backup.balances[i] = balanceOf[holders[i]];
            delete balanceOf[holders[i]];
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
        oracleConnector = oldState.oracleConnector;
        lastSeenTokenPrice = oldState.lastSeenTokenPrice;
        maxTotalAssetsInUnderlying = oldState.maxTotalAssetsInUnderlying;
        address[19] memory holders = getHolders();
        uint256 holdersBalance;
        for (uint256 i = 0; i < 19; i++) {
            balanceOf[holders[i]] = oldState.balances[i];
            holdersBalance += oldState.balances[i];
        }
        require(baseTotalSupply == holdersBalance, Mismatch(baseTotalSupply, holdersBalance));
        vaultBalanceAsLendingConnector = ILendingConnector(newFields.vaultBalanceAsLendingConnector);
        slippageProvider = ISlippageProvider(newFields.slippageProvider);
        modules = IModules(newFields.modules);
        governor = newFields.governor;
        guardian = newFields.guardian;
        emergencyDeleverager = newFields.emergencyDeleverager;
        auctionDuration = newFields.auctionDuration;
        maxGrowthFeeDividend = newFields.maxGrowthFeeDividend;
        maxGrowthFeeDivider = newFields.maxGrowthFeeDivider;
        maxDeleverageFeeDividend = newFields.maxDeleverageFeeDividend;
        maxDeleverageFeeDivider = newFields.maxDeleverageFeeDivider;
        maxSafeLTVDividend = newFields.maxSafeLTVDividend;
        maxSafeLTVDivider = newFields.maxSafeLTVDivider;
        minProfitLTVDividend = newFields.minProfitLTVDividend;
        minProfitLTVDivider = newFields.minProfitLTVDivider;
        targetLTVDividend = newFields.targetLTVDividend;
        targetLTVDivider = newFields.targetLTVDivider;
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
        NewFields calldata newFields
    ) public {
        ProxyAdmin proxyAdmin = ProxyAdmin(_proxyAdmin);
        OldStateCleaner oldStateCleaner = new OldStateCleaner();
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), address(oldStateCleaner), "");
        OldStateBackup memory oldState = OldStateCleaner(proxy).cleanAndBackup(newFields.allowances);
        NewStateRemapper newStateRemapper = new NewStateRemapper();
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), address(newStateRemapper), "");
        NewStateRemapper(proxy).remapState(oldState, newFields);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), newImplementation, "");
        proxyAdmin.transferOwnership(newProxyAdminOwner);
    }
}

contract DeployGhostUpgrade is Script, StdCheats, StdAssertions {
    function getApprovalLogs(address proxy) internal returns (ApprovalData[] memory) {
        bytes32[] memory topics = new bytes32[](1);
        topics[0] = keccak256("Approval(address,address,uint256)");
        Vm.EthGetLogs[] memory logs = vm.eth_getLogs(0, block.number, proxy, topics);
        ApprovalData[] memory approvals = new ApprovalData[](logs.length);
        for (uint256 i = 0; i < logs.length; i++) {
            approvals[i] = ApprovalData({
                owner: address(uint160(uint256(logs[i].topics[1]))),
                spender: address(uint160(uint256(logs[i].topics[2]))),
                amount: abi.decode(logs[i].data, (uint256))
            });
        }
        return approvals;
    }

    function run() public {
        address proxy = vm.envAddress("PROXY");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        address ltv = vm.envAddress("LTV");
        ApprovalData[] memory allowances = getApprovalLogs(proxy);
        NewFields memory newFields = NewFields({
            vaultBalanceAsLendingConnector: vm.envAddress("VAULT_BALANCE_AS_LENDING_CONNECTOR"),
            slippageProvider: vm.envAddress("SLIPPAGE_CONNECTOR"),
            governor: vm.envAddress("GOVERNOR"),
            guardian: vm.envAddress("GUARDIAN"),
            emergencyDeleverager: vm.envAddress("EMERGENCY_DELEVERAGER"),
            modules: vm.envAddress("MODULES_PROVIDER"),
            lendingConnector: vm.envAddress("LENDING_CONNECTOR"),
            auctionDuration: 1000,
            maxGrowthFeeDividend: 1,
            maxGrowthFeeDivider: 5,
            maxDeleverageFeeDividend: 1,
            maxDeleverageFeeDivider: 50,
            maxSafeLTVDividend: 9,
            maxSafeLTVDivider: 10,
            minProfitLTVDividend: 5,
            minProfitLTVDivider: 10,
            targetLTVDividend: 75,
            targetLTVDivider: 100,
            boolSlot: 0,
            allowances: allowances
        });
        // vm.startBroadcast();
        vm.startPrank(msg.sender);
        Upgrader upgrader = new Upgrader{salt: bytes32(0)}(msg.sender);

        vm.store(proxyAdmin, 0, bytes32(uint256(uint160(msg.sender))));

        console.log("proxyAdmin", proxyAdmin);
        console.log("proxyAdmin admin", address(uint160(uint256(vm.load(proxyAdmin, 0)))));
        console.log("msg.sender", msg.sender);

        ProxyAdmin(proxyAdmin).transferOwnership(address(upgrader));
        upgrader.upgrade(proxy, proxyAdmin, ltv, msg.sender, newFields);
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
