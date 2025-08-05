// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "forge-std/console.sol";

abstract contract BaseScript is Script {
    function run() external {
        bool deployRequested = vm.envOr("DEPLOY", false);
        if (deployRequested) {
            if (isContractDeployed()) {
                console.log(
                    string.concat("Contract already deployed at: ", vm.toString(expectedAddress(hashedCreationCode())))
                );
                return;
            }

            vm.startBroadcast();
            deploy();
            vm.stopBroadcast();
        } else {
            console.log("Expected address: ", expectedAddress(hashedCreationCode()));
        }
    }

    function deploy() internal virtual;

    function hashedCreationCode() internal view virtual returns (bytes32);

    function expectedAddress(bytes32 _hashedCreationCode) internal view virtual returns (address) {
        bytes32 hashed = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(0x4e59b44847b379578588920cA78FbF26c0B4956C), bytes32(0), _hashedCreationCode
            )
        );
        return address(uint160(uint256(hashed)));
    }

    function isContractDeployed() internal view returns (bool) {
        address _expectedAddress = expectedAddress(hashedCreationCode());
        return _expectedAddress.code.length > 0;
    }
}
