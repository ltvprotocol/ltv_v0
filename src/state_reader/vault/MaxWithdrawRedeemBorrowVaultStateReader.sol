// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemBorrowVaultState} from "../../structs/state/vault/max/MaxWithdrawRedeemBorrowVaultState.sol";
import {PreviewWithdrawVaultStateReader} from "./PreviewWithdrawVaultStateReader.sol";

/**
 * @title MaxWithdrawRedeemBorrowVaultStateReader
 * @notice contract contains functionality to retrieve pure state needed for
 * max withdraw redeem borrow vault operations calculations
 */
contract MaxWithdrawRedeemBorrowVaultStateReader is PreviewWithdrawVaultStateReader {
    /**
     * @dev function to retrieve pure state needed for max withdraw redeem borrow vault operations
     */
    function maxWithdrawRedeemBorrowVaultState(address owner)
        internal
        view
        returns (MaxWithdrawRedeemBorrowVaultState memory)
    {
        return MaxWithdrawRedeemBorrowVaultState({
            previewWithdrawVaultState: previewWithdrawVaultState(),
            maxSafeLtvDividend: maxSafeLtvDividend,
            maxSafeLtvDivider: maxSafeLtvDivider,
            ownerBalance: balanceOf[owner]
        });
    }
}
