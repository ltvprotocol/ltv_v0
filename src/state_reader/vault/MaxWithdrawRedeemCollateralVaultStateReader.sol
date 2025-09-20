// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemCollateralVaultState} from
    "src/structs/state/vault/max/MaxWithdrawRedeemCollateralVaultState.sol";
import {PreviewWithdrawVaultStateReader} from "src/state_reader/vault/PreviewWithdrawVaultStateReader.sol";

/**
 * @title MaxWithdrawRedeemCollateralVaultStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max withdraw redeem collateral vault operations calculations
 */
contract MaxWithdrawRedeemCollateralVaultStateReader is PreviewWithdrawVaultStateReader {
    /**
     * @dev function to retrieve pure state needed for max withdraw redeem collateral vault operations
     */
    function maxWithdrawRedeemCollateralVaultState(address owner)
        internal
        view
        returns (MaxWithdrawRedeemCollateralVaultState memory)
    {
        return MaxWithdrawRedeemCollateralVaultState({
            previewWithdrawVaultState: previewWithdrawVaultState(),
            maxSafeLtvDividend: maxSafeLtvDividend,
            maxSafeLtvDivider: maxSafeLtvDivider,
            ownerBalance: balanceOf[owner]
        });
    }
}
