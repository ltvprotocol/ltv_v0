// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract CommonWrite {

    function makeDelegateUInt256(bytes memory data, address impl) internal returns(uint256) {
        (bool success, bytes memory returnData) = impl.delegatecall(data);
        require(success, "Delegate-call failed");
        return abi.decode(returnData, (uint256));
    }

    function makeDelegateInt256(bytes memory data, address impl) internal returns(int256) {
        (bool success, bytes memory returnData) = impl.delegatecall(data);
        require(success, "Delegate-call failed");
        return abi.decode(returnData, (int256));
    }

    function makeDelegateBool(bytes memory data, address impl) internal returns(bool) {
        (bool success, bytes memory returnData) = impl.delegatecall(data);
        require(success, "Delegate-call failed");
        return abi.decode(returnData, (bool));
    }

}