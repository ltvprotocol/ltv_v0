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
            // price borrow / collateral = 0.8210526666117071
            sharesAfter1LowLevelRebalanceDeposit: 206414624751756084009,
            collateralAfter1LowLevelRebalanceDeposit: 169477278080277037591, // 0 loss
            borrowAfter1LowLevelRebalanceDeposit: 0,
            sharesAfter1LowLevelRebalanceWithdraw: 20641462475175608400,
            collateralAfter1LowLevelRebalanceWithdraw: 0,
            borrowAfter1LowLevelRebalanceWithdraw: 20563262716780913683, // 0.38% loss
            assetsAfter1SafeDeposit: 3715463245531609512, // 5.7% loss, 0.5% slippage x 12x leverage ~ 6% loss
            sharesAfter1SafeDeposit: 3504157278961091433,
            assetsAfter1SafeMint: 3343916920978448560, // 5.7% loss, 0.5% slippage x 12x leverage ~ 6% loss
            sharesAfter1SafeMint: 3153741551064982290,
            assetsAfter1SafeDepositCollateral: 2745531904897363969, // 5.2% loss, 0.5% slippage x (12-1)x leverage ~ 5.5% loss
            sharesAfter1SafeDepositCollateral: 3169589498557771146,
            assetsAfter1SafeMintCollateral: 2470978714407627572, // 5.2% loss, 0.5% slippage x (12-1)x leverage ~ 5.5% loss
            sharesAfter1SafeMintCollateral: 2852630548701994032,
            borrowAfter1DepositAuctionExecution: 146540687816654286186,
            collateralAfter1DepositAuctionExecution: 120016828442730243901, // 0.25% profit since auction half opened
            assetsAfter1SafeWithdrawCollateral: 2506778395218842440,
            sharesAfter1SafeWithdrawCollateral: 3231767835484402340, // 5.5% loss, 0.5% slippage x (12-1)x leverage ~ 5.5% loss
            assetsAfter1SafeRedeemCollateral: 2256100555696958196,
            sharesAfter1SafeRedeemCollateral: 2908591051935962105, // 5.5% loss, 0.5% slippage x (12-1)x leverage ~ 5.5% loss
            assetsAfter1SafeWithdraw: 2296387967637595924,
            sharesAfter1SafeWithdraw: 2442965923018719068, // 6% loss, 0.5% slippage x 12x leverage ~ 6% loss
            assetsAfter1SafeRedeem: 2066749170873836332,
            sharesAfter1SafeRedeem: 2198669330716847162, // 6% loss, 0.5% slippage x 12x leverage ~ 6% loss
            sharesAfter2SafeDeposit: 5084723616011977221, // 3% profit for half opened auction cancellation
            assetsAfter2SafeDeposit: 4927464122733256282,
            collateralAfter1WithdrawAuctionExecution: 49820811018338885258,
            borrowAfter1WithdrawAuctionExecution: 60527492342090447783 // 0.25% profit since auction half opened
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
