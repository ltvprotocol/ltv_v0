// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxDepositMintCollateralVaultState} from "../../structs/state/vault/max/MaxDepositMintCollateralVaultState.sol";
import {PreviewDepositVaultStateReader} from "PreviewDepositVaultStateReader.sol";

/**
 * @title MaxDepositMintCollateralVaultStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max deposit mint collateral vault operations calculations
 */
contract MaxDepositMintCollateralVaultStateReader is PreviewDepositVaultStateReader {
    /**
     * @dev function to retrieve pure state needed for max deposit mint collateral vault operations
     */
    function maxDepositMintCollateralVaultState() internal view returns (MaxDepositMintCollateralVaultState memory) {
        return MaxDepositMintCollateralVaultState({
            previewDepositVaultState: previewDepositVaultState(),
            minProfitLtvDividend: minProfitLtvDividend,
            minProfitLtvDivider: minProfitLtvDivider,
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
