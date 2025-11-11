// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {TestGeneralDeployedLTVBeaconProxy, ExpectedResults} from "./TestGeneralDeployedLTVBeaconProxy.s.sol";
import {IFlashLoanLidoMintHelper} from "./interface/IFlashLoanLidoMintHelper.s.sol";
import {IFlashLoanLidoRedeemHelper} from "./interface/IFlashLoanLidoRedeemHelper.s.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWstEth {
    // forge-lint: disable-next-line
    function stETH() external view returns (address);
}

interface IStEth {
    function getTotalPooledEther() external view returns (uint256);
    function getTotalShares() external view returns (uint256);
}

// forge-lint: disable-start(unsafe-typecast)

contract TestLidoDeployedLtvBeaconProxy is TestGeneralDeployedLTVBeaconProxy {
    IFlashLoanLidoMintHelper public flashLoanLidoMintHelper;
    IFlashLoanLidoRedeemHelper public flashLoanLidoRedeemHelper;

    function _beforeTest() internal override {
        super._beforeTest();
        flashLoanLidoMintHelper = IFlashLoanLidoMintHelper(vm.envAddress("MINT_HELPER"));
        flashLoanLidoRedeemHelper = IFlashLoanLidoRedeemHelper(vm.envAddress("REDEEM_HELPER"));
        whitelistRegistry.addAddressToWhitelist(address(flashLoanLidoMintHelper));
        whitelistRegistry.addAddressToWhitelist(address(flashLoanLidoRedeemHelper));
    }

    function _expectedResults() internal pure override returns (ExpectedResults memory) {
        return ExpectedResults({
            sharesAfter1LowLevelRebalanceDeposit: 129009140469847552506,
            collateralAfter1LowLevelRebalanceDeposit: 105923298800173148496,
            borrowAfter1LowLevelRebalanceDeposit: 0,
            sharesAfter1LowLevelRebalanceWithdraw: 12900914046984755250,
            collateralAfter1LowLevelRebalanceWithdraw: 0,
            borrowAfter1LowLevelRebalanceWithdraw: 12852763152687249351,
            assetsAfter1SafeDeposit: 682989567193310572,
            sharesAfter1SafeDeposit: 663048265961389094,
            sharesAfter1SafeMint: 596743439365250185,
            assetsAfter1SafeMint: 614690610473979515,
            assetsAfter1SafeDepositCollateral: 498181192420892655,
            sharesAfter1SafeDepositCollateral: 590519823577545659,
            sharesAfter1SafeMintCollateral: 531467841219791094,
            assetsAfter1SafeMintCollateral: 448363073178803391,
            borrowAfter1DepositAuctionExecution: 27497253249031026534,
            collateralAfter1DepositAuctionExecution: 22548472238233581124,
            assetsAfter1SafeWithdrawCollateral: 1167438422678020829,
            sharesAfter1SafeWithdrawCollateral: 1462191102414486265,
            sharesAfter1SafeRedeemCollateral: 1315971992173037637,
            assetsAfter1SafeRedeemCollateral: 1050694580410218746,
            assetsAfter1SafeWithdraw: 1066410052136880959,
            sharesAfter1SafeWithdraw: 1099391806326681402,
            sharesAfter1SafeRedeem: 989452625694013261,
            assetsAfter1SafeRedeem: 959769046923192863,
            sharesAfter2SafeDeposit: 1163658442973837539,
            assetsAfter2SafeDeposit: 1145937756024997376,
            collateralAfter1WithdrawAuctionExecution: 34095007275773684324,
            borrowAfter1WithdrawAuctionExecution: 41474061167361209100
        });
    }

    function _receiveCollateralTokens(uint256 collateralAmount) internal override {
        address wstEth = ltv.assetCollateral();

        IStEth stEth = IStEth(IWstEth(wstEth).stETH());

        uint256 etherNeeded =
            (collateralAmount * stEth.getTotalPooledEther() + stEth.getTotalShares() - 1) / stEth.getTotalShares();

        deal(user, etherNeeded);
        uint256 initialBalance = IERC20(wstEth).balanceOf(user);

        (bool success,) = wstEth.call{value: etherNeeded}("");
        require(success, "Failed to wrap ether");

        assertEq(IERC20(wstEth).balanceOf(user), initialBalance + collateralAmount);
    }

    function _previewMintWithLowLevelRebalance(int256 shares) internal view override returns (int256, int256) {
        uint256 collateralAmount = flashLoanLidoMintHelper.previewMintSharesWithFlashLoanCollateral(uint256(shares));
        return (int256(collateralAmount), 0);
    }

    function _executeMintWithLowLevelRebalance(int256 shares) internal override {
        flashLoanLidoMintHelper.mintSharesWithFlashLoanCollateral(uint256(shares));
    }

    function _previewRedeemWithLowLevelRebalance(int256 shares) internal view override returns (int256, int256) {
        uint256 borrowAmount = flashLoanLidoRedeemHelper.previewRedeemSharesWithCurveAndFlashLoanBorrow(uint256(shares));
        return (0, -int256(borrowAmount));
    }

    function _executeRedeemWithLowLevelRebalance(int256 shares) internal override {
        flashLoanLidoRedeemHelper.redeemSharesWithCurveAndFlashLoanBorrow(uint256(shares), 0);
    }

    function _redeemWithLowLevelRebalanceApproveTarget() internal view override returns (address) {
        return address(flashLoanLidoRedeemHelper);
    }

    function _mintWithLowLevelRebalanceApproveTarget() internal view override returns (address) {
        return address(flashLoanLidoMintHelper);
    }
}
// forge-lint: disable-end(unsafe-typecast)
