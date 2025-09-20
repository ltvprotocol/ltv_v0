// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BalancedTest} from "test/utils/BalancedTest.t.sol";
import {ILTV} from "src/interfaces/ILTV.sol";
import {IAdministrationErrors} from "src/errors/IAdministrationErrors.sol";
import {WhitelistRegistry} from "src/elements/WhitelistRegistry.sol";

contract WhitelistTest is BalancedTest {
    function test_whitelist(address owner, address user, address randUser)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        vm.assume(user != randUser);
        vm.assume(user != ltv.feeCollector());
        vm.stopPrank();
        address governor = ILTV(address(dummyLtv)).governor();
        vm.startPrank(governor);
        deal(address(borrowToken), randUser, type(uint112).max);

        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(governor, address(0));
        dummyLtv.setWhitelistRegistry(address(whitelistRegistry));

        dummyLtv.setIsWhitelistActivated(true);
        whitelistRegistry.addAddressToWhitelist(randUser);

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAdministrationErrors.ReceiverNotWhitelisted.selector, user));
        dummyLtv.deposit(10 ** 17, user);

        vm.startPrank(randUser);
        borrowToken.approve(address(dummyLtv), 10 ** 17);
        dummyLtv.deposit(10 ** 17, randUser);
    }

    function test_whitelistSignature(address owner, uint256 signerPrivateKey, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        signerPrivateKey = signerPrivateKey % SECP256K1_ORDER + 1;
        vm.stopPrank();
        address signer = vm.addr(signerPrivateKey);
        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(owner, signer);

        bytes32 hash = keccak256(abi.encodePacked(block.chainid, address(whitelistRegistry), user));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, hash);

        assertEq(whitelistRegistry.isAddressWhitelisted(user), false);
        vm.startPrank(user);
        whitelistRegistry.addAddressToWhitelistBySignature(user, v, r, s);

        assertEq(whitelistRegistry.isAddressWhitelisted(user), true);
    }

    function test_whitelistImpossibleDoubleApproval(address owner, uint256 signerPrivateKey, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        signerPrivateKey = signerPrivateKey % SECP256K1_ORDER + 1;
        vm.stopPrank();
        address signer = vm.addr(signerPrivateKey);
        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(owner, signer);

        uint8 v;
        bytes32 r;
        bytes32 s;

        {
            bytes32 digest = keccak256(abi.encodePacked(block.chainid, address(whitelistRegistry), user));
            (v, r, s) = vm.sign(signerPrivateKey, digest);
        }
        assertEq(whitelistRegistry.isAddressWhitelisted(user), false);
        vm.startPrank(user);
        whitelistRegistry.addAddressToWhitelistBySignature(user, v, r, s);
        vm.stopPrank();

        assertEq(whitelistRegistry.isAddressWhitelisted(user), true);

        vm.prank(owner);
        whitelistRegistry.removeAddressFromWhitelist(user);
        assertEq(whitelistRegistry.isAddressWhitelisted(user), false);

        vm.expectRevert(abi.encodeWithSelector(WhitelistRegistry.DoubleSignatureUse.selector));
        whitelistRegistry.addAddressToWhitelistBySignature(user, v, r, s);
    }

    function _createInvalidSignature(uint256 signerPrivateKey, WhitelistRegistry whitelistRegistry)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // Create signature for a different user to make it invalid
        address differentUser = address(0x1234567890123456789012345678901234567890);
        bytes32 digest = keccak256(abi.encodePacked(block.chainid, address(whitelistRegistry), differentUser));
        return vm.sign(signerPrivateKey, digest);
    }

    function test_incorrectSignature(address owner, uint256 signerPrivateKey, address user)
        public
        initializeBalancedTest(owner, user, 10 ** 17, 0, 0, 0)
    {
        signerPrivateKey = signerPrivateKey % SECP256K1_ORDER + 1;
        vm.stopPrank();

        address signer = vm.addr(signerPrivateKey);
        WhitelistRegistry whitelistRegistry = new WhitelistRegistry(owner, signer);
        (uint8 v, bytes32 r, bytes32 s) = _createInvalidSignature(signerPrivateKey, whitelistRegistry);

        assertEq(whitelistRegistry.isAddressWhitelisted(user), false);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(WhitelistRegistry.InvalidSignature.selector));
        whitelistRegistry.addAddressToWhitelistBySignature(user, v, r, s);
    }
}
