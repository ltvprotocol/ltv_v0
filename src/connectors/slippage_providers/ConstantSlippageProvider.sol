// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../../interfaces/ISlippageProvider.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ConstantSlippageProvider is ISlippageProvider, Ownable {
    uint256 public override collateralSlippage;
    uint256 public override borrowSlippage;

    constructor(uint256 _collateralSlippage, uint256 _borrowSlippage, address initialOwner) Ownable(initialOwner) {
        collateralSlippage = _collateralSlippage;
        borrowSlippage = _borrowSlippage;     
    }

    function setCollateralSlippage(uint256 _collateralSlippage) external onlyOwner {
        collateralSlippage = _collateralSlippage;
    }

    function setBorrowSlippage(uint256 _borrowSlippage) external onlyOwner {
        borrowSlippage = _borrowSlippage;
    }
}