// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './UpgradeableOwnableWithGovernor.sol';
import './UpgradeableOwnableWithGuardian.sol';

abstract contract UpgradeableOwnableWithGuardianAndGovernor is UpgradeableOwnableWithGovernor, UpgradeableOwnableWithGuardian {
    function __Ownable_With_Guardian_And_Governor_init(address _guardian, address _governor, address _owner) internal onlyInitializing {
        __Ownable_init_unchained(_owner);
        __Ownable_With_Guardian_init_unchained(_guardian);
        __Ownable_With_Governor_init_unchained(_governor);
    }
}
