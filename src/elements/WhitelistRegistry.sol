// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IWhitelistRegistry} from "src/interfaces/IWhitelistRegistry.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title WhitelistRegistry
 * @notice This contract is used to manage the whitelist of addresses. LTV protocol uses
 * this contract to allow only whitelisted addresses to receive any assets from the protocol.
 * Contract has owner, which can add and remove addresses from the whitelist. Also user
 * can add to whitelist himself by submitting signature of the signer. User can acquire whitelist
 * by signature only once.
 */
contract WhitelistRegistry is IWhitelistRegistry, Ownable {
    mapping(address => bool) public isAddressWhitelisted;
    mapping(address => bool) public wasWhitelistedBySignature;
    address public signer;

    event AddressWhitelisted(address indexed account, bool isWhitelisted);
    event SignerUpdated(address indexed signer);

    error InvalidSignature();
    error DoubleSignatureUse();

    struct WhitelistApproval {
        address whitelistedAddress;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(address initialOwner, address initialSigner) Ownable(initialOwner) {
        signer = initialSigner;
    }

    /**
     * @notice Add an address to the whitelist
     */
    function addAddressToWhitelist(address account) external onlyOwner {
        isAddressWhitelisted[account] = true;
        emit AddressWhitelisted(account, true);
    }

    /**
     * @notice Remove an address from the whitelist
     */
    function removeAddressFromWhitelist(address account) external onlyOwner {
        isAddressWhitelisted[account] = false;
        emit AddressWhitelisted(account, false);
    }

    /**
     * @notice Update the signer
     */
    function updateSigner(address newSigner) external onlyOwner {
        signer = newSigner;
        emit SignerUpdated(signer);
    }

    /**
     * @notice Add an address to the whitelist by signature(can be called only once per address)
     */
    function addAddressToWhitelistBySignature(address account, uint8 v, bytes32 r, bytes32 s) external {
        // forge-lint: disable-next-line(asm-keccak256)
        bytes32 digest = keccak256(abi.encodePacked(block.chainid, address(this), account));
        require(ECDSA.recover(digest, v, r, s) == signer, InvalidSignature());
        require(!wasWhitelistedBySignature[account], DoubleSignatureUse());
        wasWhitelistedBySignature[account] = true;
        isAddressWhitelisted[account] = true;
        emit AddressWhitelisted(account, true);
    }
}
