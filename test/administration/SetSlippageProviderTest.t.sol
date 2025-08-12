// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../utils/BaseTest.t.sol";
import "../../src/connectors/slippage_providers/ConstantSlippageProvider.sol";

contract SetSlippageProviderTest is BaseTest {
    function test_failIfNotGovernor(DefaultTestData memory defaultData, address user)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.assume(user != defaultData.governor);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.OnlyGovernorInvalidCaller.selector, user));
        ltv.setSlippageProvider(address(0));
    }

    function test_checkSlot(DefaultTestData memory defaultData) public testWithPredefinedDefaultValues(defaultData) {
        vm.startPrank(defaultData.governor);
        ConstantSlippageProvider provider = new ConstantSlippageProvider();
        ltv.setSlippageProvider(address(provider));
        vm.stopPrank();

        assertEq(address(ltv.slippageProvider()), address(provider));
    }

    function test_slippageChanged(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        uint256 initialCollateralSlippage = ISlippageProvider(ltv.slippageProvider()).collateralSlippage(ltv.slippageProviderGetterData());
        uint256 initialBorrowSlippage = ISlippageProvider(ltv.slippageProvider()).borrowSlippage(ltv.slippageProviderGetterData());

        vm.startPrank(defaultData.governor);
        uint256 newCollateralSlippage = 3 * 10 ** 16;
        uint256 newBorrowSlippage = 25 * 10 ** 15;
        ConstantSlippageProvider provider =
            new ConstantSlippageProvider();
        ltv.setSlippageProvider(address(provider));
        vm.stopPrank();

        assertNotEq(ISlippageProvider(ltv.slippageProvider()).collateralSlippage(ltv.slippageProviderGetterData()), initialCollateralSlippage);
        assertNotEq(ISlippageProvider(ltv.slippageProvider()).borrowSlippage(ltv.slippageProviderGetterData()), initialBorrowSlippage);
        assertEq(ISlippageProvider(ltv.slippageProvider()).collateralSlippage(ltv.slippageProviderGetterData()), newCollateralSlippage);
        assertEq(ISlippageProvider(ltv.slippageProvider()).borrowSlippage(ltv.slippageProviderGetterData()), newBorrowSlippage);
    }

    function test_failIfZeroSlippageProvider(DefaultTestData memory defaultData)
        public
        testWithPredefinedDefaultValues(defaultData)
    {
        vm.startPrank(defaultData.governor);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ZeroSlippageProvider.selector));
        ltv.setSlippageProvider(address(0));
    }
}
