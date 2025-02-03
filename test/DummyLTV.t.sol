// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../src/ltv_lendings/DummyLTV.sol";
import "../src/dummy/DummyOracle.sol";
import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {MockDummyLending} from "./utils/MockDummyLending.sol";
import "../src/Constants.sol";

contract DummyLTVTest is Test {
    DummyLTV public dummyLTV;
    MockERC20 public collateralToken;
    MockERC20 public borrowToken;
    MockDummyLending public lendingProtocol;
    IDummyOracle public oracle;

    modifier initializeTest(
        address owner,
        uint160 amount,
        address user
    ) {
        collateralToken = new MockERC20();
        collateralToken.initialize("Collateral", "COL", 18);
        borrowToken = new MockERC20();
        borrowToken.initialize("Borrow", "BOR", 18);

        lendingProtocol = new MockDummyLending(owner);
        oracle = IDummyOracle(new DummyOracle(owner));

        dummyLTV = new DummyLTV(
            owner,
            address(collateralToken),
            address(borrowToken),
            lendingProtocol,
            oracle
        );

        vm.startPrank(owner);
        Ownable(address(lendingProtocol)).transferOwnership(address(dummyLTV));
        oracle.setAssetPrice(address(borrowToken), 1000000);
        oracle.setAssetPrice(address(collateralToken), 2000000);

        deal(address(collateralToken), user, amount);
        deal(address(borrowToken), address(lendingProtocol), amount);

        lendingProtocol.setSupplyBalance(address(collateralToken), amount * 10);
        lendingProtocol.setBorrowBalance(address(borrowToken),
            (((amount * oracle.getAssetPrice(address(collateralToken))) /
                oracle.getAssetPrice(address(borrowToken))) *
                Constants.TARGET_LTV) / Constants.TARGET_LTV_DEVIDER
        );

        vm.startPrank(user);
        _;
    }

    function test_basic(
        address owner,
        uint160 amount,
        address user
    ) public initializeTest(owner, amount, user) {
        collateralToken.approve(address(dummyLTV), amount);
        dummyLTV.deposit(amount, user);
    }
}
