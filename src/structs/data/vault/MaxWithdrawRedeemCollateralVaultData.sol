// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewCollateralVaultData} from "src/structs/data/vault/PreviewCollateralVaultData.sol";

struct MaxWithdrawRedeemCollateralVaultData {
    PreviewCollateralVaultData previewCollateralVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint16 maxSafeLTVDividend;
    uint16 maxSafeLTVDivider;
    uint256 ownerBalance;
}
