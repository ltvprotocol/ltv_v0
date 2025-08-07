// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../../interfaces/ISlippageProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ConstantSlippageProvider is ISlippageProvider {
    uint256 public immutable override collateralSlippage;
    uint256 public immutable override borrowSlippage;

    constructor(uint256 _collateralSlippage, uint256 _borrowSlippage) {
        collateralSlippage = _collateralSlippage;
        borrowSlippage = _borrowSlippage;
    }
}
