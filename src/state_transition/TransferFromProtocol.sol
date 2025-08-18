// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/modifiers/WhitelistModifier.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TransferFromProtocol is WhitelistModifier {
    using SafeERC20 for IERC20;

    function transferBorrowToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        borrowToken.safeTransfer(to, amount);
    }

    function transferCollateralToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        collateralToken.safeTransfer(to, amount);
    }
}
