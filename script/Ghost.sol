// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {Upgrades} from 'openzeppelin-foundry-upgrades/Upgrades.sol';

import {ProxyAdmin} from '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

import {MagicETH} from 'src/ghost/magic/MagicETH.sol';

import {HodlMyBeerLending} from 'src/ghost/hodlmybeer/HodlMyBeerLending.sol';

import {SpookyOracle} from 'src/ghost/spooky/SpookyOracle.sol';

import {WETH} from '../src/dummy/weth/WETH.sol';

import '../src/ltv_lendings/GhostLTV.sol';

import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        // TODO: deploy LTV also

        address proxyOwner = vm.envAddress('PROXY_OWNER');
        address magicETHOwner = vm.envAddress('MAGIC_ETH_OWNER');
        address oracleOwner = vm.envAddress('ORACLE_OWNER');
        address weth = vm.envAddress('WETH');
        address ltvOwner = vm.envAddress('LTV_OWNER');
        address feeCollector = vm.envAddress('FEE_COLLECTOR');

        console.log('proxyOwner: ', proxyOwner);
        console.log('magicETHOwner: ', magicETHOwner);
        console.log('oracleOwner: ', oracleOwner);
        console.log('weth: ', weth);

        vm.startBroadcast(); // Start broadcasting transactions

        address magicETHProxy = Upgrades.deployTransparentProxy('MagicETH.sol', proxyOwner, abi.encodeCall(MagicETH.initialize, (magicETHOwner)));

        // ------------------------------------------------

        address spookyOracleProxy = Upgrades.deployTransparentProxy(
            'SpookyOracle.sol',
            proxyOwner,
            abi.encodeCall(SpookyOracle.initialize, oracleOwner)
        );

        // ------------------------------------------------

        // TODO: add link to WETH

        address hodlMyBeerLendingProxy = Upgrades.deployTransparentProxy(
            'HodlMyBeerLending.sol',
            proxyOwner,
            abi.encodeCall(HodlMyBeerLending.initialize, (weth, address(magicETHProxy), address(spookyOracleProxy)))
        );

        address ltv = Upgrades.deployTransparentProxy(
            'GhostLTV.sol',
            proxyOwner,
            abi.encodeCall(
                GhostLTV.initialize,
                (ltvOwner, IHodlMyBeerLending(hodlMyBeerLendingProxy), ISpookyOracle(spookyOracleProxy), magicETHProxy, weth, feeCollector)
            )
        );

        // ------------------------------------------------

        GhostLTV(ltv).setMaxSafeLTV(9 * 10 ** 17);
        GhostLTV(ltv).setMinProfitLTV(5 * 10 ** 17);
        GhostLTV(ltv).setTargetLTV(75 * 10 ** 16);

        MagicETH(magicETHProxy).mint(msg.sender, type(uint112).max);
        MagicETH(magicETHProxy).approve(ltv, type(uint112).max);

        SpookyOracle(spookyOracleProxy).setAssetPrice(weth, 10 ** 18);
        SpookyOracle(spookyOracleProxy).setAssetPrice(magicETHProxy, 10 ** 18);

        WETH(payable(weth)).deposit{value: 500 * 10 ** 18}();
        WETH(payable(weth)).transfer(hodlMyBeerLendingProxy, 500 * 10 ** 18);

        uint256 shares = GhostLTV(ltv).firstTimeDeposit(100 * 10 ** 18, 75 * 10 ** 18);

        console.log('shares: ', shares);
        console.log('hodl my beer liquidity weth      ', WETH(payable(weth)).balanceOf(hodlMyBeerLendingProxy));
        console.log('hodl my beer liquidity magic eth ', MagicETH(magicETHProxy).balanceOf(hodlMyBeerLendingProxy));

        WETH(payable(weth)).approve(ltv, 10 * 10 ** 18);
        
        uint256 shares2 = GhostLTV(ltv).deposit(10*10**18, address(123));
        console.log("shares2: ", shares2);
        console.log("balanceOf", GhostLTV(ltv).balanceOf(address(123)));


        WETH(payable(weth)).approve(ltv, 38834951456310679610);
        GhostLTV(ltv).executeAuctionBorrow(-38834951456310679610);

        vm.stopBroadcast();
        console.log("currentPrice", GhostLTV(ltv).convertToShares(10**18));
        console.log("futureCollateralAssets", GhostLTV(ltv).futureCollateralAssets());
        console.log("futureBorrowAssets", GhostLTV(ltv).futureBorrowAssets());
        console.log("futureRewardCollateralAssets", GhostLTV(ltv).futureRewardCollateralAssets());
        console.log("futureRewardBorrowAssets", GhostLTV(ltv).futureRewardBorrowAssets());
        console.log("real collateral", IHodlMyBeerLending(hodlMyBeerLendingProxy).supplyBalance(ltv));
        console.log("real borrow    ", IHodlMyBeerLending(hodlMyBeerLendingProxy).borrowBalance(ltv));

        console.log('proxyMagicETH at:         ', magicETHProxy);
        console.log('hodlMyBeerLendingProxy at:', hodlMyBeerLendingProxy);
        console.log('spookyOracleProxy at:     ', spookyOracleProxy);
        console.log('ltv at:                   ', ltv);
    }
}
