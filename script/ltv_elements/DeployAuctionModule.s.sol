// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {AuctionModule} from "../../src/elements/AuctionModule.sol";
import {console} from "forge-std/console.sol";

contract DeployAuctionModule is BaseScript {
    function deploy() internal override {
        AuctionModule auctionModule = new AuctionModule{salt: bytes32(0)}();
        console.log("AuctionModule deployed at: ", address(auctionModule));
    }

    function hashedCreationCode() internal pure override returns (bytes32) {
        return keccak256(type(AuctionModule).creationCode);
    }
}
