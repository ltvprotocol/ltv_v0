// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, DefaultTestData} from "test/utils/BaseTest.t.sol";
import {ISlippageConnector} from "src/interfaces/connectors/ISlippageConnector.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {ConstantSlippageConnector} from "src/connectors/slippage_connectors/ConstantSlippageConnector.sol";

contract SetSlippageConnectorTest is BaseTest {
    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setSlippageConnector(address(0), abi.encode(10 ** 16, 10 ** 16));
    }

    function test_checkSlot(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ConstantSlippageConnector provider = new ConstantSlippageConnector();
        ltv.setSlippageConnector(address(provider), abi.encode(10 ** 16, 10 ** 16));
        vm.stopPrank();

        assertEq(address(ltv.slippageConnector()), address(provider));
    }

    function test_slippageChanged(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint256 initialCollateralSlippage =
            ISlippageConnector(ltv.slippageConnector()).collateralSlippage(ltv.slippageConnectorGetterData());
        uint256 initialBorrowSlippage =
            ISlippageConnector(ltv.slippageConnector()).borrowSlippage(ltv.slippageConnectorGetterData());

        vm.startPrank(defaultData.governor);
        uint256 newCollateralSlippage = 3 * 10 ** 16;
        uint256 newBorrowSlippage = 25 * 10 ** 15;
        ConstantSlippageConnector provider = new ConstantSlippageConnector();
        ltv.setSlippageConnector(address(provider), abi.encode(newCollateralSlippage, newBorrowSlippage));
        vm.stopPrank();

        assertNotEq(
            ISlippageConnector(ltv.slippageConnector()).collateralSlippage(ltv.slippageConnectorGetterData()),
            initialCollateralSlippage
        );
        assertNotEq(
            ISlippageConnector(ltv.slippageConnector()).borrowSlippage(ltv.slippageConnectorGetterData()),
            initialBorrowSlippage
        );
        assertEq(
            ISlippageConnector(ltv.slippageConnector()).collateralSlippage(ltv.slippageConnectorGetterData()),
            newCollateralSlippage
        );
        assertEq(
            ISlippageConnector(ltv.slippageConnector()).borrowSlippage(ltv.slippageConnectorGetterData()),
            newBorrowSlippage
        );
    }

    function test_failIfZeroSlippageConnector(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroSlippageConnector.selector));
        ltv.setSlippageConnector(address(0), abi.encode(10 ** 16, 10 ** 16));
    }
}
