// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract Lending {
    function borrow(uint256) virtual internal;

    function repay(uint256) virtual internal;

    function supply(uint256) virtual internal;

    function withdraw(uint256) virtual internal;
}