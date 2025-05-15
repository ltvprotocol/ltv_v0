// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/IModules.sol";
import "../../states/LTVState.sol";

abstract contract AdministrationRead is LTVState {
    // TEMPORARY HOTFIX TO MAKE TESTS PASS BEFORE REFACTORING
    function owner() external view returns (address) {
        uint256 _owner;
        assembly {
            _owner := sload(0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300)
        }
        return address(uint160(_owner));
    }

    function guardian() external view returns (address) {
        uint256 _guardian;
        assembly {
            _guardian := sload(0xb60e8a6cf2c094d0527dfea44fb0b4bf02c33935fafc6f6e4cbe2a9f9dd8b0b3)
        }
        return address(uint160(_guardian));
    }

    function emergencyDeleverager() external view returns (address) {
        uint256 _emergencyDeleverager;
        assembly {
            _emergencyDeleverager := sload(0x46798bb8057efc5a1d6baf4083b6bd07e15b2aa35542d5edffc59f448755677e)
        }
        return address(uint160(_emergencyDeleverager));
    }

    function governor() external view returns (address) {
        uint256 _governor;
        assembly {
            _governor := sload(0xda3ee8bcb5d3050b69493a59eb63b65657bdfb51032a8d53879973fe01319f9b)
        }
        return address(uint160(_governor));
    }
}
