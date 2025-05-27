// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../src/dummy/DummyOracle.sol';
import 'forge-std/Test.sol';
import {MockERC20} from 'forge-std/mocks/MockERC20.sol';
import {MockDummyLending} from './MockDummyLending.t.sol';
import '../utils/DummyLTV.t.sol';
import '../../src/Constants.sol';
import '../../src/dummy/DummyLendingConnector.sol';
import '../../src/dummy/DummyOracleConnector.sol';
import '../../src/utils/ConstantSlippageProvider.sol';
import '../../src/utils/WhitelistRegistry.sol';
import '../../src/utils/VaultBalanceAsLendingConnector.sol';
import '../../src/utils/Timelock.sol';
import {ILTV} from '../../src/interfaces/ILTV.sol';
import {IAdministrationErrors} from '../../src/errors/IAdministrationErrors.sol';

import './modules/DummyBorrowVaultModule.t.sol';
import './modules/DummyCollateralVaultModule.t.sol';
import './modules/DummyERC20Module.t.sol';
import './modules/DummyLowLevelRebalanceModule.t.sol';
import {AuctionModule} from 'src/elements/AuctionModule.sol';
import {AdministrationModule} from 'src/elements/AdministrationModule.sol';
import 'src/utils/VaultBalanceAsLendingConnector.sol';

import 'src/elements/ModulesProvider.sol';

contract BaseTest is Test {
    DummyLTV public dummyLTV;
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;
    ConstantSlippageProvider public slippageProvider;

    modifier initializeBalancedTest(
        address owner,
        address user,
        uint256 borrowAmount,
        int256 futureBorrow,
        int256 futureCollateral,
        int256 auctionReward
    ) {
        vm.assume(owner != address(0));
        vm.assume(user != address(0));
        vm.assume(user != owner);
        vm.assume(int256(borrowAmount) >= futureBorrow);
        collateralToken = new MockERC20();
        collateralToken.initialize('Collateral', 'COL', 18);
        borrowToken = new MockERC20();
        borrowToken.initialize('Borrow', 'BOR', 18);

        lendingProtocol = new MockDummyLending(owner);
        oracle = IDummyOracle(new DummyOracle(owner));
        slippageProvider = new ConstantSlippageProvider(0, 0, owner);
        {
            ModulesState memory modulesState = ModulesState({
                administrationModule: IAdministrationModule(address(new AdministrationModule())),
                auctionModule: IAuctionModule(address(new AuctionModule())),
                erc20Module: IERC20Module(address(new DummyERC20Module())),
                collateralVaultModule: ICollateralVaultModule(address(new DummyCollateralVaultModule())),
                borrowVaultModule: IBorrowVaultModule(address(new DummyBorrowVaultModule())),
                lowLevelRebalanceModule: ILowLevelRebalanceModule(address(new DummyLowLevelRebalanceModule()))
            });

            StateInitData memory initData = StateInitData({
                name: 'Dummy LTV',
                symbol: 'DLTV',
                decimals: 18,
                collateralToken: address(collateralToken),
                borrowToken: address(borrowToken),
                feeCollector: owner,
                maxSafeLTV: 9 * 10 ** 17,
                minProfitLTV: 5 * 10 ** 17,
                targetLTV: 75 * 10 ** 16,
                lendingConnector: new DummyLendingConnector(collateralToken, borrowToken, lendingProtocol),
                oracleConnector: new DummyOracleConnector(collateralToken, borrowToken, oracle),
                maxGrowthFee: 10 ** 18 / 5,
                maxTotalAssetsInUnderlying: type(uint128).max,
                slippageProvider: slippageProvider,
                maxDeleverageFee: 2 * 10 ** 16,
                vaultBalanceAsLendingConnector: new VaultBalanceAsLendingConnector(collateralToken, borrowToken),
                modules: new ModulesProvider(modulesState),
                owner: owner,
                guardian: address(123),
                governor: address(132),
                emergencyDeleverager: address(213),
                callData: ''
            });

            dummyLTV = new DummyLTV(initData);
        }

        vm.startPrank(owner);
        Ownable(address(lendingProtocol)).transferOwnership(address(dummyLTV));
        oracle.setAssetPrice(address(borrowToken), 100 * 10 ** 18);
        oracle.setAssetPrice(address(collateralToken), 200 * 10 ** 18);

        deal(address(borrowToken), address(lendingProtocol), type(uint112).max);
        deal(address(borrowToken), user, type(uint112).max);
        deal(address(collateralToken), address(lendingProtocol), type(uint112).max);
        deal(address(collateralToken), user, type(uint112).max);

        dummyLTV.mintFreeTokens(borrowAmount * 10, owner);

        vm.roll(Constants.AMOUNT_OF_STEPS);
        dummyLTV.setStartAuction(Constants.AMOUNT_OF_STEPS / 2);
        dummyLTV.setFutureBorrowAssets(futureBorrow);
        dummyLTV.setFutureCollateralAssets(futureCollateral / 2);

        if (futureBorrow < 0) {
            lendingProtocol.setSupplyBalance(address(collateralToken), uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2));
            lendingProtocol.setBorrowBalance(address(borrowToken), uint256(int256(borrowAmount) * 10 * 3 - futureBorrow - auctionReward));
            dummyLTV.setFutureRewardBorrowAssets(auctionReward);
        } else {
            lendingProtocol.setSupplyBalance(
                address(collateralToken),
                uint256(int256(borrowAmount) * 5 * 4 - futureCollateral / 2 - auctionReward / 2)
            );
            lendingProtocol.setBorrowBalance(address(borrowToken), uint256(int256(borrowAmount) * 10 * 3 - futureBorrow));
            dummyLTV.setFutureRewardCollateralAssets(auctionReward / 2);
        }

        vm.startPrank(user);
        collateralToken.approve(address(dummyLTV), type(uint112).max);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        _;
    }
}
