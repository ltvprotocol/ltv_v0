// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/interfaces/IOracleConnector.sol";

contract MockOracleConnector is IOracleConnector {
    bool public shouldRevert;
    uint256 public collateralPrice;
    uint256 public borrowPrice;

    constructor(uint256 _collateralPrice, uint256 _borrowPrice, bool _shouldRevert) {
        collateralPrice = _collateralPrice;
        borrowPrice = _borrowPrice;
        shouldRevert = _shouldRevert;
    }

    function getPriceCollateralOracle() external view returns (uint256) {
        if (shouldRevert) {
            revert();
        }
        return collateralPrice;
    }

    function getPriceBorrowOracle() external view returns (uint256) {
        if (shouldRevert) {
            revert();
        }
        return borrowPrice;
    }
}

contract SetOracleConnectorTest is BaseTest {
    function test_setAndCheckAppliedChanges(
        DefaultTestData memory defaultData,
        uint256 newCollateralPrice,
        uint256 newBorrowPrice
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(newCollateralPrice > 0 && newCollateralPrice <= type(uint128).max);
        vm.assume(newBorrowPrice > 0 && newBorrowPrice <= type(uint128).max);

        address initialOracleConnector = address(ltv.oracleConnector());

        MockOracleConnector newOracleConnector = new MockOracleConnector(newCollateralPrice, newBorrowPrice, false);

        vm.startPrank(defaultData.owner);
        ltv.setOracleConnector(address(newOracleConnector));
        vm.stopPrank();

        address updatedOracleConnector = address(ltv.oracleConnector());
        assertEq(updatedOracleConnector, address(newOracleConnector));
        assertNotEq(updatedOracleConnector, initialOracleConnector);

        assertEq(ltv.oracleConnector().getPriceCollateralOracle(), newCollateralPrice);
        assertEq(ltv.oracleConnector().getPriceBorrowOracle(), newBorrowPrice);
    }

    function test_mockOracleConnectorWithDeposit(
        DefaultTestData memory defaultData,
        address user,
        uint256 depositAmount
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(user != address(0));
        vm.assume(user != defaultData.owner);
        vm.assume(depositAmount > 0 && depositAmount <= type(uint128).max);

        MockOracleConnector revertingOracleConnector = new MockOracleConnector(10 ** 18, 10 ** 18, true);

        vm.startPrank(defaultData.owner);
        ltv.setOracleConnector(address(revertingOracleConnector));
        vm.stopPrank();

        deal(address(ltv.collateralToken()), user, depositAmount);

        vm.startPrank(user);
        ltv.collateralToken().approve(address(ltv), depositAmount);

        try ltv.deposit(depositAmount, user) {
            revert();
        } catch {}
        vm.stopPrank();
    }

    function test_onlyOwnerCanSetOracleConnector(
        DefaultTestData memory defaultData,
        address nonOwner,
        uint256 collateralPrice,
        uint256 borrowPrice
    ) public testWithPredefinedDefaultValues(defaultData) {
        vm.assume(nonOwner != address(0));
        vm.assume(nonOwner != defaultData.owner);
        vm.assume(nonOwner != defaultData.guardian);
        vm.assume(nonOwner != defaultData.governor);
        vm.assume(nonOwner != defaultData.emergencyDeleverager);
        vm.assume(nonOwner != defaultData.feeCollector);
        vm.assume(collateralPrice > 0 && collateralPrice <= type(uint128).max);
        vm.assume(borrowPrice > 0 && borrowPrice <= type(uint128).max);

        MockOracleConnector newOracleConnector = new MockOracleConnector(collateralPrice, borrowPrice, false);

        vm.startPrank(nonOwner);
        vm.expectRevert();
        ltv.setOracleConnector(address(newOracleConnector));
        vm.stopPrank();

        vm.startPrank(defaultData.guardian);
        vm.expectRevert();
        ltv.setOracleConnector(address(newOracleConnector));
        vm.stopPrank();

        vm.startPrank(defaultData.governor);
        vm.expectRevert();
        ltv.setOracleConnector(address(newOracleConnector));
        vm.stopPrank();

        vm.startPrank(defaultData.emergencyDeleverager);
        vm.expectRevert();
        ltv.setOracleConnector(address(newOracleConnector));
        vm.stopPrank();

        vm.startPrank(defaultData.owner);
        ltv.setOracleConnector(address(newOracleConnector));
        vm.stopPrank();

        assertEq(address(ltv.oracleConnector()), address(newOracleConnector));
    }
}
