// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {LTV} from '../src/LTV.sol';
import {HodlLendingConnector} from '../src/ghost/connectors/HodlLendingConnector.sol';
import {SpookyOracleConnector} from '../src/ghost/connectors/SpookyOracleConnector.sol';
import {IHodlMyBeerLending} from '../src/ghost/hodlmybeer/IHodlMyBeerLending.sol';
import {ConstantSlippageProvider} from '../src/utils/ConstantSlippageProvider.sol';
import {ISpookyOracle} from '../src/ghost/spooky/ISpookyOracle.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import 'forge-std/StdAssertions.sol';
import 'forge-std/StdCheats.sol';
import 'forge-std/Script.sol';

contract GhostUpgradeCommon is Script {
    address internal constant LTV_ADDRESS = 0xE2A7f267124AC3E4131f27b9159c78C521A44F3c;
    address internal constant PROXY_ADMIN_ADDRESS = 0xCeF37fa937b8b38DEA0BdF417074025aE916E8D0;
    address internal constant COLLATERAL_TOKEN = 0x8f7b2044F9aA6fbf495c1cC3bDE120dF9032aE43;
    address internal constant BORROW_TOKEN = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address internal constant PROXY_ADMIN_OWNER = 0xe79782D86D26c745B3407e102A9D3Ea1A7158929;

    function upgrade() internal {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_ADDRESS);

        LTV ltvImpl = new LTV();

        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(LTV_ADDRESS), address(ltvImpl), '');
        console.log('Upgraded LTV to: ', address(ltvImpl));
    }

    function setMissingSlots(address slippageProviderOwner) internal {
        address _lendingProtocol = 0x1Dcd756db287354c4607D5d57621cdfb4456E2d4;
        address _oracle = 0x6074D1d4022521147DB1faD7BACC486B35A64dF3;

        HodlLendingConnector lendingConnector = new HodlLendingConnector(
            IERC20(COLLATERAL_TOKEN),
            IERC20(BORROW_TOKEN),
            IHodlMyBeerLending(_lendingProtocol)
        );

        SpookyOracleConnector oracleConnector = new SpookyOracleConnector(IERC20(COLLATERAL_TOKEN), IERC20(BORROW_TOKEN), ISpookyOracle(_oracle));

        ConstantSlippageProvider slippageProvider = new ConstantSlippageProvider(10 ** 16, 10 ** 16, slippageProviderOwner);

        LTV(LTV_ADDRESS).setMissingSlots(lendingConnector, oracleConnector, slippageProvider);

        console.log('Lending connector is at ', address(lendingConnector));
        console.log('Oracle connector is at ', address(oracleConnector));
    }
}

contract GhostUpgradeTest is GhostUpgradeCommon, StdAssertions, StdCheats {
    function run() public {
        LTV ltv = LTV(LTV_ADDRESS);
        uint256 depositAmount = 10 ** 16;
        uint256 oldPreview = ltv.previewDeposit(depositAmount);
        
        vm.startPrank(PROXY_ADMIN_OWNER);
        upgrade();
        vm.stopPrank();
        vm.startPrank(ltv.owner());
        setMissingSlots(address(this));

        vm.startPrank(address(this));
        deal(BORROW_TOKEN, address(this), depositAmount);
        IERC20(BORROW_TOKEN).approve(LTV_ADDRESS, depositAmount);
        assertEq(ltv.deposit(depositAmount, address(this)), oldPreview - 100);
        require(ltv.maxDeposit(address(this)) > 0);
        ltv.previewLowLevelShares(0);
    }
}

contract GhostUpgradeScript is GhostUpgradeCommon {
    function run() public {
        uint256 proxyAdminOwnerPrivateKey = vm.envUint('PROXY_ADMIN_OWNER_PRIVATE_KEY');
        uint256 ltvOwnerPrivateKey = vm.envUint('LTV_OWNER_PRIVATE_KEY');
        address slippageProviderOwner = vm.envAddress('SLIPPAGE_PROVIDER_OWNER');

        require(vm.addr(proxyAdminOwnerPrivateKey) == PROXY_ADMIN_OWNER, 'Invalid proxy admin owner private key');
        require(vm.addr(ltvOwnerPrivateKey) == LTV(LTV_ADDRESS).owner(), 'Invalid LTV owner private key');

        vm.startBroadcast(proxyAdminOwnerPrivateKey);
        upgrade();
        vm.stopBroadcast();
        vm.startBroadcast(ltvOwnerPrivateKey);
        setMissingSlots(slippageProviderOwner);
        vm.stopBroadcast();
    }
}
