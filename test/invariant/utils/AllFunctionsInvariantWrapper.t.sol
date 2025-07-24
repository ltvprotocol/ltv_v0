// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./AuctionInvariantWrapper.t.sol";
import "./VaultInvariantWrapper.t.sol";
import "./LowLevelRebalanceInvariantWrapper.t.sol";

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
