// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ISpookyOracle {
    /// @notice Gets the price of a given asset.
    /// @param asset The address of the asset.
    /// @return price The price of the asset.
    function getAssetPrice(address asset) external view returns (uint256);

    /// @notice Sets the price of a given asset (only callable by the owner).
    /// @param asset The address of the asset.
    /// @param price The price to set for the asset.
    /// @return price The price that was set.
    function setAssetPrice(address asset, uint256 price) external returns (uint256);
}
