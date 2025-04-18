// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import 'forge-std/Test.sol';
contract Impl {
    address public addr;
    uint256 public amount;
    function transfer(address _address, uint256 _amount) external returns(uint256, string memory) {
        addr = _address;
        amount = _amount;
        return (amount, "test");
    }
}

contract DelegateTestContract {
    address public addr;
    uint256 public amount;
    address public impl;
    constructor (address _impl) {
        impl = _impl;
    }

    function transfer(address _to, uint256 _amount) external returns(uint256, string memory) {
        _delegate(impl, abi.encode(_to, _amount));
    }

    function _delegate(address implementation, bytes memory encodedParams) internal virtual {
        (bool result, bytes memory data) = implementation.delegatecall(bytes.concat(msg.sig, encodedParams));
        
        assembly {
            switch result
            case 0 {
                revert(add(data, 32), mload(data))
            }
            default {
                return(add(data, 32), mload(data))
            }
        }
    }
}

contract DelegateTest is Test {
    function test_delegate() public {
        vm.startBroadcast();

        // Deploy the implementation contract
        Impl implContract = new Impl();
        
        // Deploy the test contract with the implementation address
        DelegateTestContract testContract = new DelegateTestContract(address(implContract));
        
        // Test the transfer function with delegation
        uint256 testAmount = 100;
        address testAddress = address(0x123);
        
        // Call transfer and get the return value
        (uint256 returnedAmount, string memory test) = testContract.transfer(testAddress, testAmount);
        
        // Verify the delegation worked correctly
        assertEq(test, "test");
        assertEq(testContract.amount(), testAmount);
        assertEq(testContract.addr(), testAddress);
        assertEq(returnedAmount, testAmount);
        
        console.log("Test passed: Delegation and return value working correctly");
        console.log("Implementation contract:", address(implContract));
        console.log("Test contract:", address(testContract));
        console.log("Delegated amount:", testAmount);
        console.log("Returned amount:", returnedAmount);

        vm.stopBroadcast();
    }
}
