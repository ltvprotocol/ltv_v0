// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewDepositVaultStateReader.sol";
import "src/structs/state/vault/MaxDepositMintCollateralVaultState.sol";

contract MaxDepositMintCollateralVaultStateReader is PreviewDepositVaultStateReader {
    function maxDepositMintCollateralVaultState() internal view returns (MaxDepositMintCollateralVaultState memory) {
        return MaxDepositMintCollateralVaultState({
            previewDepositVaultState: previewDepositVaultState(),
            minProfitLTVDividend: minProfitLTVDividend,
            minProfitLTVDivider: minProfitLTVDivider,
            maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
        });
    }
}
