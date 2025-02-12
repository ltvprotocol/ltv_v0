// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.13;

// import "../Constants.sol";
// import "./TotalAssets.sol";
// import "../math/DepositWithdrawCollateral.sol";
// import "../math/MintRedeemCollateral.sol";

// abstract contract PreviewDepositCollateral is TotalAssets, DepositWithdrawCollateral, MintRedeemCollateral {

//     using uMulDiv for uint256;

//     function previewDepositCollateral(uint256 assets) public view returns (uint256 shares) {

//         int256 sharesInUnderlying = previewDepositWithdrawCollateral(-1*int256(assets));
        
//         uint256 sharesInAssets;
//         if (sharesInUnderlying < 0) {
//             return 0;
//         } else {
//             sharesInAssets = uint256(sharesInUnderlying).mulDivDown(Constants.ORACLE_DIVIDER, getPrices().collateral);
//         }

//         return sharesInAssets.mulDivDown(totalSupply(), totalAssets());
//     }

// }