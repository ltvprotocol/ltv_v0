// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {DeltaSharesAndDeltaRealBorrowData} from "src/structs/data/vault/delta_real_borrow/DeltaSharesAndDeltaRealBorrowData.sol";
import {DeltaSharesAndDeltaRealCollateralData} from "src/structs/data/vault/delta_real_collateral/DeltaSharesAndDeltaRealCollateralData.sol";
import {DeltaRealBorrowAndDeltaRealCollateralData} from
    "src/structs/data/vault/delta_real_collateral/DeltaRealBorrowAndDeltaRealCollateralData.sol";

interface IVaultErrors {
    error DeltaSharesAndDeltaRealBorrowUnexpectedError(DeltaSharesAndDeltaRealBorrowData data);
    error DeltaSharesAndDeltaRealCollateralUnexpectedError(DeltaSharesAndDeltaRealCollateralData data);
    error DeltaRealBorrowAndDeltaRealCollateralUnexpectedError(DeltaRealBorrowAndDeltaRealCollateralData data);
    error ExceedsMaxDeposit(address receiver, uint256 assets, uint256 max);
    error ExceedsMaxWithdraw(address owner, uint256 assets, uint256 max);
    error ExceedsMaxMint(address receiver, uint256 shares, uint256 max);
    error ExceedsMaxRedeem(address owner, uint256 shares, uint256 max);
    error ExceedsMaxDepositCollateral(address receiver, uint256 assets, uint256 max);
    error ExceedsMaxWithdrawCollateral(address owner, uint256 assets, uint256 max);
    error ExceedsMaxMintCollateral(address receiver, uint256 shares, uint256 max);
    error ExceedsMaxRedeemCollateral(address owner, uint256 shares, uint256 max);
}
