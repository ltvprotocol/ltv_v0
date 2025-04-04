
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../src/dummy/DummyOracle.sol';
import '../src/utils/ConstantSlippageProvider.sol';
import 'forge-std/Test.sol';
import {MockERC20} from 'forge-std/mocks/MockERC20.sol';
import {MockDummyLending} from './utils/MockDummyLending.t.sol';
import './utils/DummyLTV.t.sol';
import '../src/Constants.sol';
import '../src/dummy/DummyLendingConnector.sol';
import '../src/dummy/DummyOracleConnector.sol';

contract GeneratedTests is Test {
    DummyLTV public dummyLTV;
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;

    modifier initializeTest(
        uint256 realBorrow,
        uint256 realCollateral,
        int256 futureBorrow,
        int256 futureCollateral,
        int256 auctionReward,
        uint16 auctionStep
    ) {
        address owner = msg.sender;

        collateralToken = new MockERC20();
        collateralToken.initialize('Collateral', 'COL', 18);
        borrowToken = new MockERC20();
        borrowToken.initialize('Borrow', 'BOR', 18);

        lendingProtocol = new MockDummyLending(owner);
        oracle = IDummyOracle(new DummyOracle(owner));

        ILendingConnector lendingConnector = new DummyLendingConnector(
            collateralToken,
            borrowToken,
            lendingProtocol
        );

        IOracleConnector oracleConnector = new DummyOracleConnector(
            collateralToken,
            borrowToken,
            oracle
        );

        ConstantSlippageProvider slippageProvider = new ConstantSlippageProvider(
            10**16,
            10**16,
            owner
        );

        State.StateInitData memory initData = State.StateInitData({
            collateralToken: address(collateralToken),
            borrowToken: address(borrowToken),
            feeCollector: address(123),
            maxSafeLTV: 9*10**17,
            minProfitLTV: 5*10**17,
            targetLTV: 75*10**16,
            lendingConnector: lendingConnector,
            oracleConnector: oracleConnector,
            maxGrowthFee: 10**18 / 5,
            maxTotalAssetsInUnderlying: type(uint128).max,
            slippageProvider: slippageProvider
        }); 

        dummyLTV = new DummyLTV(initData, owner);

        vm.startPrank(owner);
        Ownable(address(lendingProtocol)).transferOwnership(address(dummyLTV));
        oracle.setAssetPrice(address(borrowToken), 100 * 10 ** 18);
        oracle.setAssetPrice(address(collateralToken), 100 * 10 ** 18);

        lendingProtocol.setBorrowBalance(address(borrowToken), realBorrow);
        lendingProtocol.setSupplyBalance(address(collateralToken), realCollateral);

        vm.roll(Constants.AMOUNT_OF_STEPS);
        dummyLTV.setStartAuction(auctionStep);
        dummyLTV.setFutureBorrowAssets(futureBorrow);
        dummyLTV.setFutureCollateralAssets(futureCollateral);
          
        if (auctionReward > 0) {
          dummyLTV.setFutureRewardBorrowAssets(auctionReward);
        } else {
          dummyLTV.setFutureRewardCollateralAssets(auctionReward);
        }
        dummyLTV.mintFreeTokens((dummyLTV.totalAssets() - 1) * 100, address(this));
        vm.stopPrank();

        deal(address(borrowToken), address(lendingProtocol), type(uint112).max);
        deal(address(collateralToken), address(lendingProtocol), type(uint112).max);
        deal(address(borrowToken), address(this), type(uint112).max);
        deal(address(collateralToken), address(this), type(uint112).max);
        borrowToken.approve(address(dummyLTV), type(uint112).max);
        collateralToken.approve(address(dummyLTV), type(uint112).max);
        _;
      }

      
  function test_borrow_cna_deposit() public initializeTest(56000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(1000);
      uint256 deltaShares = dummyLTV.deposit(1000, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
      assertEq(dummyLTV.futureBorrowAssets(), 5000);
      assertEq(dummyLTV.futureCollateralAssets(), 5000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cna_mint() public initializeTest(56000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewMint(1000 * 100);
      uint256 deltaBorrow = dummyLTV.mint(1000 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 1000);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
      assertEq(dummyLTV.futureBorrowAssets(), 5000);
      assertEq(dummyLTV.futureCollateralAssets(), 5000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cna_withdraw() public initializeTest(54000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(1000);
      uint256 deltaShares = dummyLTV.withdraw(1000, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
      assertEq(dummyLTV.futureBorrowAssets(), 5000);
      assertEq(dummyLTV.futureCollateralAssets(), 5000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cna_redeem() public initializeTest(54000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(100000);
      uint256 deltaBorrow = dummyLTV.redeem(100000, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 1000);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
      assertEq(dummyLTV.futureBorrowAssets(), 5000);
      assertEq(dummyLTV.futureCollateralAssets(), 5000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmbc_deposit() public initializeTest(55000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(2060);
      uint256 deltaShares = dummyLTV.deposit(2060, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1980 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
      assertEq(dummyLTV.futureBorrowAssets(), 13000);
      assertEq(dummyLTV.futureCollateralAssets(), 13000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmbc_mint() public initializeTest(55000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewMint(1980 * 100);
      uint256 deltaBorrow = dummyLTV.mint(1980 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 2060);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
      assertEq(dummyLTV.futureBorrowAssets(), 13000);
      assertEq(dummyLTV.futureCollateralAssets(), 13000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmbc_withdraw() public initializeTest(35000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(9700);
      uint256 deltaShares = dummyLTV.withdraw(9700, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 10100 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
      assertEq(dummyLTV.futureBorrowAssets(), 45000);
      assertEq(dummyLTV.futureCollateralAssets(), 45000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmbc_redeem() public initializeTest(35000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(1010000);
      uint256 deltaBorrow = dummyLTV.redeem(1010000, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 9700);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
      assertEq(dummyLTV.futureBorrowAssets(), 45000);
      assertEq(dummyLTV.futureCollateralAssets(), 45000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmcb_deposit() public initializeTest(74950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(9040);
      uint256 deltaShares = dummyLTV.deposit(9040, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 9000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmcb_mint() public initializeTest(74950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewMint(9000 * 100);
      uint256 deltaBorrow = dummyLTV.mint(9000 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 9040);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmcb_withdraw() public initializeTest(64950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(960);
      uint256 deltaShares = dummyLTV.withdraw(960, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cmcb_redeem() public initializeTest(64950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(100000);
      uint256 deltaBorrow = dummyLTV.redeem(100000, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 960);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cebc_deposit() public initializeTest(64950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(960);
      uint256 deltaShares = dummyLTV.deposit(960, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 976 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cebc_mint() public initializeTest(64950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewMint(976 * 100);
      uint256 deltaBorrow = dummyLTV.mint(976 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 960);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cebc_withdraw() public initializeTest(54950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(9040);
      uint256 deltaShares = dummyLTV.withdraw(9040, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 9024 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cebc_redeem() public initializeTest(54950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(902400);
      uint256 deltaBorrow = dummyLTV.redeem(902400, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 9040);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecb_deposit() public initializeTest(65000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(8970);
      uint256 deltaShares = dummyLTV.deposit(8970, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 8986 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecb_mint() public initializeTest(65000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewMint(8986 * 100);
      uint256 deltaBorrow = dummyLTV.mint(8986 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 8970);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecb_withdraw() public initializeTest(55000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(1030);
      uint256 deltaShares = dummyLTV.withdraw(1030, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1014 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecb_redeem() public initializeTest(55000, 75050, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(101400);
      uint256 deltaBorrow = dummyLTV.redeem(101400, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 1030);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_ceccb_deposit() public initializeTest(66000, 76040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(8010);
      uint256 deltaShares = dummyLTV.deposit(8010, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 7986 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_ceccb_mint() public initializeTest(66000, 76040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewMint(7986 * 100);
      uint256 deltaBorrow = dummyLTV.mint(7986 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 8010);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_ceccb_withdraw() public initializeTest(56000, 76040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(1990);
      uint256 deltaShares = dummyLTV.withdraw(1990, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 2014 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_ceccb_redeem() public initializeTest(56000, 76040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(201400);
      uint256 deltaBorrow = dummyLTV.redeem(201400, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 1990);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecbc_deposit() public initializeTest(64950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewDeposit(2230);
      uint256 deltaShares = dummyLTV.deposit(2230, address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 2210 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecbc_mint() public initializeTest(64950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewMint(2210 * 100);
      uint256 deltaBorrow = dummyLTV.mint(2210 * 100, address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 2230);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecbc_withdraw() public initializeTest(54950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewWithdraw(7770);
      uint256 deltaShares = dummyLTV.withdraw(7770, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 7790 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_borrow_cecbc_redeem() public initializeTest(54950, 85000, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewRedeem(779000);
      uint256 deltaBorrow = dummyLTV.redeem(779000, address(this), address(this));
      
      assertEq(deltaBorrow, preview);
      assertEq(deltaBorrow, 7770);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cna_deposit() public initializeTest(56000, 75040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(1000);
      uint256 deltaShares = dummyLTV.depositCollateral(1000, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cna_mint() public initializeTest(56000, 75040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(1000 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(1000 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 1000);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cna_withdraw() public initializeTest(56000, 77040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(1000);
      uint256 deltaShares = dummyLTV.withdrawCollateral(1000, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cna_redeem() public initializeTest(56000, 77040, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(100000);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(100000, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 1000);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmbc_deposit() public initializeTest(52940, 72990, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(2060);
      uint256 deltaShares = dummyLTV.depositCollateral(2060, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1980 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
      assertEq(dummyLTV.futureBorrowAssets(), 13000);
      assertEq(dummyLTV.futureCollateralAssets(), 13000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmbc_mint() public initializeTest(52940, 72990, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(1980 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(1980 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 2060);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
      assertEq(dummyLTV.futureBorrowAssets(), 13000);
      assertEq(dummyLTV.futureCollateralAssets(), 13000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmbc_withdraw() public initializeTest(44700, 84750, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(9700);
      uint256 deltaShares = dummyLTV.withdrawCollateral(9700, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 10100 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
      assertEq(dummyLTV.futureBorrowAssets(), 45000);
      assertEq(dummyLTV.futureCollateralAssets(), 45000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmbc_redeem() public initializeTest(44700, 84750, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(1010000);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(1010000, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 9700);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
      assertEq(dummyLTV.futureBorrowAssets(), 45000);
      assertEq(dummyLTV.futureCollateralAssets(), 45000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmcb_deposit() public initializeTest(65910, 75960, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(9040);
      uint256 deltaShares = dummyLTV.depositCollateral(9040, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 9000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmcb_mint() public initializeTest(65910, 75960, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(9000 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(9000 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 9040);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmcb_withdraw() public initializeTest(65910, 85960, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(960);
      uint256 deltaShares = dummyLTV.withdrawCollateral(960, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1000 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cmcb_redeem() public initializeTest(65910, 85960, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(100000);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(100000, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 960);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
      assertEq(dummyLTV.futureBorrowAssets(), -9000);
      assertEq(dummyLTV.futureCollateralAssets(), -9000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cebc_deposit() public initializeTest(63990, 84040, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(960);
      uint256 deltaShares = dummyLTV.depositCollateral(960, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 976 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cebc_mint() public initializeTest(63990, 84040, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(976 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(976 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 960);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cebc_withdraw() public initializeTest(63990, 94040, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(9040);
      uint256 deltaShares = dummyLTV.withdrawCollateral(9040, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 9024 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cebc_redeem() public initializeTest(63990, 94040, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(902400);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(902400, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 9040);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
      assertEq(dummyLTV.futureBorrowAssets(), -1000);
      assertEq(dummyLTV.futureCollateralAssets(), -1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecb_deposit() public initializeTest(56030, 66080, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(8970);
      uint256 deltaShares = dummyLTV.depositCollateral(8970, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 8986 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecb_mint() public initializeTest(56030, 66080, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(8986 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(8986 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 8970);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecb_withdraw() public initializeTest(56030, 76080, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(1030);
      uint256 deltaShares = dummyLTV.withdrawCollateral(1030, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 1014 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecb_redeem() public initializeTest(56030, 76080, 5000, 5000, -50, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(101400);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(101400, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 1030);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
      assertEq(dummyLTV.futureBorrowAssets(), 1000);
      assertEq(dummyLTV.futureCollateralAssets(), 1000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_ceccb_deposit() public initializeTest(57990, 68030, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(8010);
      uint256 deltaShares = dummyLTV.depositCollateral(8010, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 7986 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_ceccb_mint() public initializeTest(57990, 68030, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(7986 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(7986 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 8010);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_ceccb_withdraw() public initializeTest(57990, 78030, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(1990);
      uint256 deltaShares = dummyLTV.withdrawCollateral(1990, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 2014 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_ceccb_redeem() public initializeTest(57990, 78030, 4000, 4000, -40, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(201400);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(201400, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 1990);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
      assertEq(dummyLTV.futureBorrowAssets(), -4000);
      assertEq(dummyLTV.futureCollateralAssets(), -4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecbc_deposit() public initializeTest(62720, 82770, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewDepositCollateral(2230);
      uint256 deltaShares = dummyLTV.depositCollateral(2230, address(this));

      assertEq(deltaShares, preview);
      assertEq(deltaShares, 2210 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecbc_mint() public initializeTest(62720, 82770, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewMintCollateral(2210 * 100);
      uint256 deltaCollateral = dummyLTV.mintCollateral(2210 * 100, address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 2230);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecbc_withdraw() public initializeTest(62720, 92770, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewWithdrawCollateral(7770);
      uint256 deltaShares = dummyLTV.withdrawCollateral(7770, address(this), address(this));
      
      assertEq(deltaShares, preview);
      assertEq(deltaShares, 7790 * 100);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
  function test_collateral_cecbc_redeem() public initializeTest(62720, 92770, -5000, -5000, 50, 600.0) {
      uint256 preview = dummyLTV.previewRedeemCollateral(779000);
      uint256 deltaCollateral = dummyLTV.redeemCollateral(779000, address(this), address(this));
      
      assertEq(deltaCollateral, preview);
      assertEq(deltaCollateral, 7770);
      assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
      assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
      assertEq(dummyLTV.futureBorrowAssets(), 4000);
      assertEq(dummyLTV.futureCollateralAssets(), 4000);
      assertEq(dummyLTV.convertToShares(10**18), 10**20);
      assertApproxEqAbs((dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets() + int256(dummyLTV.getRealBorrowAssets())) * 4
        - 3 * (dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets() + int256(dummyLTV.getRealCollateralAssets())), 0, 3);
  }
}
