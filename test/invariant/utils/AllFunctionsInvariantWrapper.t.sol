// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILTV} from "src/interfaces/ILTV.sol";
import {BaseAuctionInvariantWrapper} from "test/invariant/utils/AuctionInvariantWrapper.t.sol";
import {BaseVaultInvariantWrapper, BaseInvariantWrapper} from "test/invariant/utils/VaultInvariantWrapper.t.sol";
import {BaseLowLevelRebalanceInvariantWrapper} from "test/invariant/utils/LowLevelRebalanceInvariantWrapper.t.sol";

contract AllFunctionsInvariantWrapper is
    BaseAuctionInvariantWrapper,
    BaseVaultInvariantWrapper,
    BaseLowLevelRebalanceInvariantWrapper
{
    constructor(ILTV _ltv, address[10] memory _actors) BaseInvariantWrapper(_ltv, _actors) {}

    function verifyAndResetInvariants() public override(BaseVaultInvariantWrapper, BaseInvariantWrapper) {
        BaseVaultInvariantWrapper.verifyAndResetInvariants();
    }
}
