// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseTest, BaseTestInit, DummyLendingConnector, DummyOracleConnector} from "../../utils/BaseTest.t.sol";
import "./BasicInvariantWrapper.t.sol";
import "./DynamicLending.t.sol";
import "./DynamicOracle.t.sol";

abstract contract BasicInvariantTest is BaseTest {
    function setUp() public virtual {
        BaseTestInit memory init = BaseTestInit({
            owner: address(1),
            guardian: address(2),
            governor: address(3),
            emergencyDeleverager: address(4),
            feeCollector: address(100),
            futureBorrow: 0,
            futureCollateral: 0,
            auctionReward: 0,
            startAuction: 0,
            collateralSlippage: 10 ** 16,
            borrowSlippage: 10 ** 16,
            maxTotalAssetsInUnderlying: type(uint128).max,
            collateralAssets: 2 * 10 ** 19,
            borrowAssets: 35 * 10 ** 18,
            maxSafeLTV: 9 * 10 ** 17,
            minProfitLTV: 5 * 10 ** 17,
            targetLTV: 75 * 10 ** 16,
            maxGrowthFee: 20 * 10 ** 16, // 20%
            collateralPrice: 2 * 10 ** 18,
            borrowPrice: 10 ** 18,
            maxDeleverageFee: 0,
            zeroAddressTokens: 4 * 10 ** 19 - 35 * 10 ** 18
        });

        initializeTest(init);

        vm.roll(0);

        createWrapper();

        targetContract(wrapper());

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("checkAndResetInvariants()"));
        excludeSelector(FuzzSelector({addr: wrapper(), selectors: selectors}));

        // 40 % yearly debt increase
        DynamicLending _lending = new MockDynamicLending(1000000128033583744);
        // 60 % yearly collateral price increase
        DynamicOracle _oracle = new DynamicOracle(
            address(ltv.collateralToken()),
            address(ltv.borrowToken()),
            init.collateralPrice,
            init.borrowPrice,
            1000000178844623744
        );

        vm.etch(address(oracle), address(_oracle).code);
        vm.etch(address(lendingProtocol), address(_lending).code);
    }

    function wrapper() internal view virtual returns (address);

    function createWrapper() internal virtual;

    function actors() internal virtual returns (address[10] memory) {
        address[10] memory _actors;
        for (uint256 i = 0; i < 10; i++) {
            _actors[i] = address(uint160(i + 1));
        }
        return _actors;
    }
}
