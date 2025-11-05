// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ISafe4626 {
    function safeDeposit(address vault, uint256 assets, address receiver, uint256 minSharesOut)
        external
        returns (uint256 shares);
    function safeMint(address vault, uint256 shares, address receiver, uint256 maxAssetsIn)
        external
        returns (uint256 assets);

    function safeWithdraw(address vault, uint256 assets, address receiver, uint256 maxSharesOut)
        external
        returns (uint256 shares);
    function safeRedeem(address vault, uint256 shares, address receiver, uint256 minAssetsOut)
        external
        returns (uint256 assets);
}
