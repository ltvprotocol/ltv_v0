// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

// import '../Vault.sol';
// import '../../../../math2/MintRedeem.sol';

// abstract contract PreviewMint is Vault {
//     using uMulDiv for uint256;

//     function previewMint(uint256 shares, VaultState memory state) public view returns (uint256 assets) {
//         return _previewMint(shares, vaultStateToData(state));
//     }

//     function _previewMint(uint256 shares, VaultData memory data) internal view returns (uint256 assets) {
//         uint256 sharesInUnderlying = shares.mulDivUp(data.totalAssets, data.supplyAfterFee).mulDivUp(data.borrowPrice, Constants.ORACLE_DIVIDER);

//         int256 assetsInUnderlying = MintRedeem.previewMintRedeem(int256(sharesInUnderlying), true, recoverConvertedAssets(true), prices, targetLTV);

//         if (assetsInUnderlying > 0) {
//             return 0;
//         }

//         // HODLer <=> depositor conflict, resolve in favor of HODLer, round up to receive more assets
//         return uint256(-assetsInUnderlying).mulDivUp(Constants.ORACLE_DIVIDER, prices.borrow);
//     }
// }
