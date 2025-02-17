// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../LTV.sol';
import '../dummy/interfaces/IDummyLending.sol';
import '../dummy/interfaces/IDummyOracle.sol';

contract DummyLTV is LTV {
    using uMulDiv for uint256;

    IDummyLending public lendingProtocol;
    IDummyOracle public oracle;

    constructor(address collateralToken, address borrowToken, address feeCollector) State(collateralToken, borrowToken, feeCollector) {}

    function initialize(address initialOwner, IDummyLending _lendingProtocol, IDummyOracle _oracle) public initializer {
        __Ownable_init(initialOwner);
        __ERC20_init('LTV', 'LTV', 18);
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

    function setLendingProtocol(IDummyLending _lendingProtocol) public {
        lendingProtocol = _lendingProtocol;
    }

    function setOracle(IDummyOracle _oracle) public {
        oracle = _oracle;
    }

    function borrow(uint256 assets) internal override {
        lendingProtocol.borrow(address(borrowToken), assets);
    }

    function repay(uint256 assets) internal override {
        borrowToken.approve(address(lendingProtocol), assets);
        lendingProtocol.repay(address(borrowToken), assets);
    }

    function supply(uint256 assets) internal override {
        collateralToken.approve(address(lendingProtocol), assets);
        lendingProtocol.supply(address(collateralToken), assets);
    }

    function withdraw(uint256 assets) internal override {
        lendingProtocol.withdraw(address(collateralToken), assets);
    }

    function firstTimeDeposit(uint256 collateralAssets, uint256 borrowAssets) external onlyOneTime returns (uint256) {
        uint256 sharesInUnderlying = collateralAssets.mulDivDown(getPriceCollateralOracle(), Constants.ORACLE_DIVIDER) -
            borrowAssets.mulDivDown(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);
        uint256 sharesInAssets = sharesInUnderlying.mulDivDown(getPriceBorrowOracle(), Constants.ORACLE_DIVIDER);
        uint256 shares = sharesInAssets.mulDivDown(totalSupply(), totalAssets());

        collateralToken.transferFrom(msg.sender, address(this), collateralAssets);
        supply(collateralAssets);

        _mint(msg.sender, shares);

        borrow(borrowAssets);
        borrowToken.transfer(msg.sender, borrowAssets);

        return shares;
    }
}
