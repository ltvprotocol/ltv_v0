// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../LTV.sol';
import '../ghost/spooky/ISpookyOracle.sol';
import '../ghost/hodlmybeer/IHodlMyBeerLending.sol';

contract GhostLTV is LTV {
    IHodlMyBeerLending public lendingProtocol;
    ISpookyOracle public oracle;

    // constructor(address collateralToken, address borrowToken, address feeCollector) State(collateralToken, borrowToken, feeCollector) {}

    function initialize(address initialOwner, IHodlMyBeerLending _lendingProtocol, ISpookyOracle _oracle, address collateralToken, address borrowToken, address feeCollector) public initializer {
        __State_init(collateralToken, borrowToken, feeCollector);
        __ERC20_init('Ghost Magic ETH', 'GME', 18);
        __Ownable_init(initialOwner);
        lendingProtocol = _lendingProtocol;
        oracle = _oracle;
    }

    function getPriceBorrowOracle() public view override returns (uint256) {
        return oracle.getAssetPrice(address(borrowToken));
    }

    function getPriceCollateralOracle() public view override returns (uint256) {
        return oracle.getAssetPrice(address(collateralToken));
    }

    function getRealBorrowAssets() public view override returns (uint256) {
        return lendingProtocol.borrowBalance(address(borrowToken));
    }

    function getRealCollateralAssets() public view override returns (uint256) {
        return lendingProtocol.supplyBalance(address(collateralToken));
    }

    function setLendingProtocol(IHodlMyBeerLending _lendingProtocol) public {
        lendingProtocol = _lendingProtocol;
    }

    function setOracle(ISpookyOracle _oracle) public {
        oracle = _oracle;
    }

    function borrow(uint256 assets) internal override {
        lendingProtocol.borrow(assets);
    }

    function repay(uint256 assets) internal override {
        borrowToken.approve(address(lendingProtocol), assets);
        lendingProtocol.repay(assets);
    }

    function supply(uint256 assets) internal override {
        collateralToken.approve(address(lendingProtocol), assets);
        lendingProtocol.supply(assets);
    }

    function withdraw(uint256 assets) internal override {
        lendingProtocol.withdraw(assets);
    }
}
