// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/readers/ModulesAddressStateReader.sol";
import "../writes/CommonWrite.sol";

abstract contract AuctionWrite is ModulesAddressStateReader, CommonWrite {

    function approve(address spender, uint256 amount) external returns (bool) {
        address erc20WriteAddr = IModules(getModules()).erc20Write();
        return makeDelegateBool(abi.encodeWithSignature("approve(address,uint256)", spender, amount), erc20WriteAddr);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address erc20WriteAddr = IModules(getModules()).erc20Write();
        return makeDelegateBool(abi.encodeWithSignature("transfer(address,uint256)", to, amount), erc20WriteAddr);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address erc20WriteAddr = IModules(getModules()).erc20Write();
        return makeDelegateBool(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount), erc20WriteAddr);
    }

}