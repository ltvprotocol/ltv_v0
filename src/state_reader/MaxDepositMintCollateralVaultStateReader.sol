// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import './PreviewVaultStateReader.sol';
import 'src/structs/state/vault/MaxDepositMintCollateralVaultState.sol';

contract MaxDepositMintCollateralVaultStateReader is PreviewVaultStateReader {
    function maxDepositMintCollateralVaultState() internal view returns (MaxDepositMintCollateralVaultState memory) {
        return
            MaxDepositMintCollateralVaultState({
                previewVaultState: previewVaultState(),
                minProfitLTV: minProfitLTV,
                maxTotalAssetsInUnderlying: maxTotalAssetsInUnderlying
            });
    }
} 