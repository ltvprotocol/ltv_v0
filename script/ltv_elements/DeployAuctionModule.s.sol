// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/elements/AuctionModule.sol";

contract DeployAuctionModule is BaseScript {
    function deploy() internal override {
        AuctionModule auctionModule = new AuctionModule{salt: bytes32(0)}();
        console.log("AuctionModule deployed at: ", address(auctionModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) { 
        return keccak256(type(AuctionModule).creationCode);
    }
}