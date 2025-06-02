// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewVaultStateReader.sol";
import "src/structs/state/vault/MaxWithdrawRedeemCollateralVaultState.sol";

contract MaxWithdrawRedeemCollateralVaultStateReader is PreviewVaultStateReader {
    function maxWithdrawRedeemCollateralVaultState(address owner)
        internal
        view
        returns (MaxWithdrawRedeemCollateralVaultState memory)
    {
        return MaxWithdrawRedeemCollateralVaultState({
            previewVaultState: previewVaultState(),
            maxSafeLTV: maxSafeLTV,
            ownerBalance: balanceOf[owner]
        });
    }
}
