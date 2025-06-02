// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./utils/GeneratedBaseTest.t.sol";

contract GeneratedTests is GeneratedBaseTest {
    function test_borrow_cna_deposit() public initializeGeneratedTest(56000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(1000);
        uint256 deltaShares = dummyLTV.deposit(1000, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
        assertEq(dummyLTV.futureBorrowAssets(), 5000);
        assertEq(dummyLTV.futureCollateralAssets(), 5000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cna_mint() public initializeGeneratedTest(56000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewMint(1000);
        uint256 deltaBorrow = dummyLTV.mint(1000, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
        assertEq(dummyLTV.futureBorrowAssets(), 5000);
        assertEq(dummyLTV.futureCollateralAssets(), 5000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cna_withdraw() public initializeGeneratedTest(54000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(1000);
        uint256 deltaShares = dummyLTV.withdraw(1000, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
        assertEq(dummyLTV.futureBorrowAssets(), 5000);
        assertEq(dummyLTV.futureCollateralAssets(), 5000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cna_redeem() public initializeGeneratedTest(54000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(1000);
        uint256 deltaBorrow = dummyLTV.redeem(1000, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 55000);
        assertEq(dummyLTV.futureBorrowAssets(), 5000);
        assertEq(dummyLTV.futureCollateralAssets(), 5000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmbc_deposit() public initializeGeneratedTest(55000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(2060);
        uint256 deltaShares = dummyLTV.deposit(2060, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1980);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
        assertEq(dummyLTV.futureBorrowAssets(), 13000);
        assertEq(dummyLTV.futureCollateralAssets(), 13000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmbc_mint() public initializeGeneratedTest(55000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewMint(1980);
        uint256 deltaBorrow = dummyLTV.mint(1980, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 2060);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
        assertEq(dummyLTV.futureBorrowAssets(), 13000);
        assertEq(dummyLTV.futureCollateralAssets(), 13000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmbc_withdraw() public initializeGeneratedTest(35000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(9700);
        uint256 deltaShares = dummyLTV.withdraw(9700, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 10100);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
        assertEq(dummyLTV.futureBorrowAssets(), 45000);
        assertEq(dummyLTV.futureCollateralAssets(), 45000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmbc_redeem() public initializeGeneratedTest(35000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(10100);
        uint256 deltaBorrow = dummyLTV.redeem(10100, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 9700);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
        assertEq(dummyLTV.futureBorrowAssets(), 45000);
        assertEq(dummyLTV.futureCollateralAssets(), 45000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmcb_deposit() public initializeGeneratedTest(74950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(9040);
        uint256 deltaShares = dummyLTV.deposit(9040, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 9000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmcb_mint() public initializeGeneratedTest(74950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewMint(9000);
        uint256 deltaBorrow = dummyLTV.mint(9000, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 9040);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmcb_withdraw() public initializeGeneratedTest(64950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(960);
        uint256 deltaShares = dummyLTV.withdraw(960, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cmcb_redeem() public initializeGeneratedTest(64950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(1000);
        uint256 deltaBorrow = dummyLTV.redeem(1000, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 960);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cebc_deposit() public initializeGeneratedTest(64950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(960);
        uint256 deltaShares = dummyLTV.deposit(960, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 976);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cebc_mint() public initializeGeneratedTest(64950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewMint(976);
        uint256 deltaBorrow = dummyLTV.mint(976, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 960);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cebc_withdraw() public initializeGeneratedTest(54950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(9040);
        uint256 deltaShares = dummyLTV.withdraw(9040, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 9024);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cebc_redeem() public initializeGeneratedTest(54950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(9024);
        uint256 deltaBorrow = dummyLTV.redeem(9024, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 9040);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecb_deposit() public initializeGeneratedTest(65000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(8970);
        uint256 deltaShares = dummyLTV.deposit(8970, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 8986);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecb_mint() public initializeGeneratedTest(65000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewMint(8986);
        uint256 deltaBorrow = dummyLTV.mint(8986, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 8970);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecb_withdraw() public initializeGeneratedTest(55000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(1030);
        uint256 deltaShares = dummyLTV.withdraw(1030, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1014);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecb_redeem() public initializeGeneratedTest(55000, 75050, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(1014);
        uint256 deltaBorrow = dummyLTV.redeem(1014, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 1030);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_ceccb_deposit() public initializeGeneratedTest(66000, 76040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(8010);
        uint256 deltaShares = dummyLTV.deposit(8010, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 7986);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_ceccb_mint() public initializeGeneratedTest(66000, 76040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewMint(7986);
        uint256 deltaBorrow = dummyLTV.mint(7986, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 8010);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_ceccb_withdraw() public initializeGeneratedTest(56000, 76040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(1990);
        uint256 deltaShares = dummyLTV.withdraw(1990, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 2014);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_ceccb_redeem() public initializeGeneratedTest(56000, 76040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(2014);
        uint256 deltaBorrow = dummyLTV.redeem(2014, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 1990);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecbc_deposit() public initializeGeneratedTest(64950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewDeposit(2230);
        uint256 deltaShares = dummyLTV.deposit(2230, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 2210);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecbc_mint() public initializeGeneratedTest(64950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewMint(2210);
        uint256 deltaBorrow = dummyLTV.mint(2210, address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 2230);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecbc_withdraw() public initializeGeneratedTest(54950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewWithdraw(7770);
        uint256 deltaShares = dummyLTV.withdraw(7770, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 7790);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_borrow_cecbc_redeem() public initializeGeneratedTest(54950, 85000, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewRedeem(7790);
        uint256 deltaBorrow = dummyLTV.redeem(7790, address(this), address(this));

        assertEq(deltaBorrow, preview);
        assertEq(deltaBorrow, 7770);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cna_deposit() public initializeGeneratedTest(56000, 75040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(1000);
        uint256 deltaShares = dummyLTV.depositCollateral(1000, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cna_mint() public initializeGeneratedTest(56000, 75040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(1000);
        uint256 deltaCollateral = dummyLTV.mintCollateral(1000, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cna_withdraw() public initializeGeneratedTest(56000, 77040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(1000);
        uint256 deltaShares = dummyLTV.withdrawCollateral(1000, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cna_redeem() public initializeGeneratedTest(56000, 77040, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(1000);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(1000, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56000);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmbc_deposit() public initializeGeneratedTest(52940, 72990, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(2060);
        uint256 deltaShares = dummyLTV.depositCollateral(2060, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1980);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
        assertEq(dummyLTV.futureBorrowAssets(), 13000);
        assertEq(dummyLTV.futureCollateralAssets(), 13000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmbc_mint() public initializeGeneratedTest(52940, 72990, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(1980);
        uint256 deltaCollateral = dummyLTV.mintCollateral(1980, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 2060);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 52940);
        assertEq(dummyLTV.futureBorrowAssets(), 13000);
        assertEq(dummyLTV.futureCollateralAssets(), 13000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmbc_withdraw() public initializeGeneratedTest(44700, 84750, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(9700);
        uint256 deltaShares = dummyLTV.withdrawCollateral(9700, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 10100);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
        assertEq(dummyLTV.futureBorrowAssets(), 45000);
        assertEq(dummyLTV.futureCollateralAssets(), 45000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmbc_redeem() public initializeGeneratedTest(44700, 84750, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(10100);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(10100, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 9700);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 44700);
        assertEq(dummyLTV.futureBorrowAssets(), 45000);
        assertEq(dummyLTV.futureCollateralAssets(), 45000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmcb_deposit() public initializeGeneratedTest(65910, 75960, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(9040);
        uint256 deltaShares = dummyLTV.depositCollateral(9040, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 9000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmcb_mint() public initializeGeneratedTest(65910, 75960, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(9000);
        uint256 deltaCollateral = dummyLTV.mintCollateral(9000, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 9040);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmcb_withdraw() public initializeGeneratedTest(65910, 85960, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(960);
        uint256 deltaShares = dummyLTV.withdrawCollateral(960, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1000);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cmcb_redeem() public initializeGeneratedTest(65910, 85960, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(1000);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(1000, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 960);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 65910);
        assertEq(dummyLTV.futureBorrowAssets(), -9000);
        assertEq(dummyLTV.futureCollateralAssets(), -9000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cebc_deposit() public initializeGeneratedTest(63990, 84040, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(960);
        uint256 deltaShares = dummyLTV.depositCollateral(960, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 976);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cebc_mint() public initializeGeneratedTest(63990, 84040, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(976);
        uint256 deltaCollateral = dummyLTV.mintCollateral(976, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 960);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cebc_withdraw() public initializeGeneratedTest(63990, 94040, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(9040);
        uint256 deltaShares = dummyLTV.withdrawCollateral(9040, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 9024);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cebc_redeem() public initializeGeneratedTest(63990, 94040, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(9024);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(9024, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 9040);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 63990);
        assertEq(dummyLTV.futureBorrowAssets(), -1000);
        assertEq(dummyLTV.futureCollateralAssets(), -1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecb_deposit() public initializeGeneratedTest(56030, 66080, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(8970);
        uint256 deltaShares = dummyLTV.depositCollateral(8970, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 8986);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecb_mint() public initializeGeneratedTest(56030, 66080, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(8986);
        uint256 deltaCollateral = dummyLTV.mintCollateral(8986, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 8970);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecb_withdraw() public initializeGeneratedTest(56030, 76080, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(1030);
        uint256 deltaShares = dummyLTV.withdrawCollateral(1030, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 1014);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecb_redeem() public initializeGeneratedTest(56030, 76080, 5000, 5000, -50, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(1014);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(1014, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 1030);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 75050);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 56030);
        assertEq(dummyLTV.futureBorrowAssets(), 1000);
        assertEq(dummyLTV.futureCollateralAssets(), 1000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_ceccb_deposit() public initializeGeneratedTest(57990, 68030, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(8010);
        uint256 deltaShares = dummyLTV.depositCollateral(8010, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 7986);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_ceccb_mint() public initializeGeneratedTest(57990, 68030, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(7986);
        uint256 deltaCollateral = dummyLTV.mintCollateral(7986, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 8010);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_ceccb_withdraw() public initializeGeneratedTest(57990, 78030, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(1990);
        uint256 deltaShares = dummyLTV.withdrawCollateral(1990, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 2014);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_ceccb_redeem() public initializeGeneratedTest(57990, 78030, 4000, 4000, -40, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(2014);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(2014, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 1990);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 76040);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 57990);
        assertEq(dummyLTV.futureBorrowAssets(), -4000);
        assertEq(dummyLTV.futureCollateralAssets(), -4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecbc_deposit() public initializeGeneratedTest(62720, 82770, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewDepositCollateral(2230);
        uint256 deltaShares = dummyLTV.depositCollateral(2230, address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 2210);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecbc_mint() public initializeGeneratedTest(62720, 82770, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewMintCollateral(2210);
        uint256 deltaCollateral = dummyLTV.mintCollateral(2210, address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 2230);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecbc_withdraw() public initializeGeneratedTest(62720, 92770, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewWithdrawCollateral(7770);
        uint256 deltaShares = dummyLTV.withdrawCollateral(7770, address(this), address(this));

        assertEq(deltaShares, preview);
        assertEq(deltaShares, 7790);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }

    function test_collateral_cecbc_redeem() public initializeGeneratedTest(62720, 92770, -5000, -5000, 50, 600.0) {
        uint256 preview = dummyLTV.previewRedeemCollateral(7790);
        uint256 deltaCollateral = dummyLTV.redeemCollateral(7790, address(this), address(this));

        assertEq(deltaCollateral, preview);
        assertEq(deltaCollateral, 7770);
        assertEq(lendingProtocol.supplyBalance(address(collateralToken)), 85000);
        assertEq(lendingProtocol.borrowBalance(address(borrowToken)), 62720);
        assertEq(dummyLTV.futureBorrowAssets(), 4000);
        assertEq(dummyLTV.futureCollateralAssets(), 4000);
        assertEq(dummyLTV.convertToShares(10 ** 18), 10 ** 18);
        assertApproxEqAbs(
            (
                dummyLTV.futureBorrowAssets() + dummyLTV.futureRewardBorrowAssets()
                    + int256(dummyLTV.getRealBorrowAssets(true))
            ) * 4
                - 3
                    * (
                        dummyLTV.futureCollateralAssets() + dummyLTV.futureRewardCollateralAssets()
                            + int256(dummyLTV.getRealCollateralAssets(true))
                    ),
            0,
            3
        );
    }
}
