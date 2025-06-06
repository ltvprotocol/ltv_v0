// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/interfaces/ILendingConnector.sol";

contract MockLendingConnector is ILendingConnector {
    address public collateralToken;
    address public borrowToken;
    bool public supplyCalled;
    bool public withdrawCalled;
    uint256 public lastSupplyAmount;
    uint256 public lastWithdrawAmount;

    constructor(address _collateralToken, address _borrowToken) {
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
    }

    function supply(uint256 assets) external override {
        supplyCalled = true;
        lastSupplyAmount = assets;
        MockERC20(collateralToken).transferFrom(msg.sender, address(this), assets);
    }

    function withdraw(uint256 assets) external override {
        withdrawCalled = true;
        lastWithdrawAmount = assets;
        MockERC20(collateralToken).transfer(msg.sender, assets);
    }

    function borrow(uint256 assets) external override {
        MockERC20(borrowToken).transfer(msg.sender, assets);
    }

    function repay(uint256 assets) external override {
        MockERC20(borrowToken).transferFrom(msg.sender, address(this), assets);
    }

    function getRealCollateralAssets(bool) external view override returns (uint256) {
        return MockERC20(collateralToken).balanceOf(address(this));
    }

    function getRealBorrowAssets(bool) external view override returns (uint256) {
        return MockERC20(borrowToken).balanceOf(address(this));
    }

    function reset() external {
        supplyCalled = false;
        withdrawCalled = false;
        lastSupplyAmount = 0;
        lastWithdrawAmount = 0;
    }
}

contract SetLendingConnectorTest is BaseTest {
    MockLendingConnector public mockLendingConnector;

    function testSetAndCheckStorage(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockLendingConnector = new MockLendingConnector(address(collateralToken), address(borrowToken));

        address initialLendingConnector = address(ltv.getLendingConnector());

        vm.startPrank(defaultData.owner);
        ltv.setLendingConnector(address(mockLendingConnector));
        vm.stopPrank();

        assertEq(address(ltv.getLendingConnector()), address(mockLendingConnector));
        assertNotEq(address(ltv.getLendingConnector()), initialLendingConnector);
    }

    function testMockExecution(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        mockLendingConnector = new MockLendingConnector(address(collateralToken), address(borrowToken));

        vm.prank(defaultData.owner);
        ltv.setLendingConnector(address(mockLendingConnector));

        assertEq(address(ltv.getLendingConnector()), address(mockLendingConnector));

        vm.startPrank(address(ltv));

        mockLendingConnector.reset();

        assertEq(mockLendingConnector.supplyCalled(), false);
        assertEq(mockLendingConnector.lastSupplyAmount(), 0);

        uint256 testAmount = 100;
        deal(address(collateralToken), address(ltv), testAmount);
        collateralToken.approve(address(mockLendingConnector), testAmount);

        mockLendingConnector.supply(testAmount);

        vm.stopPrank();

        assertEq(mockLendingConnector.supplyCalled(), true);
        assertEq(mockLendingConnector.lastSupplyAmount(), testAmount);
    }

    function test_RevertIf_NotOwner(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.owner);
        vm.assume(user != defaultData.governor);

        mockLendingConnector = new MockLendingConnector(address(collateralToken), address(borrowToken));

        vm.startPrank(user);
        vm.expectRevert();
        ltv.setLendingConnector(address(mockLendingConnector));
        vm.stopPrank();
    }
}
