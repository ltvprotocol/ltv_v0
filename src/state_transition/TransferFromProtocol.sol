// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {WhitelistModifier} from "src/modifiers/WhitelistModifier.sol";
import {ITransferFromProtocolErrors} from "src/errors/ITransferFromProtocolErrors.sol";

/**
 * @title TransferFromProtocol
 * @notice contract contains functionality to transfer tokens from the protocol.
 * @dev All the possible token transfers from the protocol have to be implemented through this contract.
 * It helps to whitelist all the users who can interact with the protocol. Also it helps to avoid transferring tokens to zero address.
 */
abstract contract TransferFromProtocol is WhitelistModifier, ITransferFromProtocolErrors {
    using SafeERC20 for IERC20;

    function transferBorrowToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        require(to != address(0), TransferBorrowTokenToZeroAddress());
        borrowToken.safeTransfer(to, amount);
    }

    function transferCollateralToken(address to, uint256 amount) internal isReceiverWhitelisted(to) {
        require(to != address(0), TransferCollateralTokenToZeroAddress());
        collateralToken.safeTransfer(to, amount);
    }
}
