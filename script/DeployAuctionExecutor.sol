// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import 'forge-std/Script.sol';

import './AuctionExecutor.sol';

// LTV=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 AUCTION_EXECUTOR_OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 forge script script/DeployAuctionExecutor.sol --rpc-url 127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
contract DeployAuctionExecutor is Script {
    function run() public {
        address ltv = vm.envAddress('LTV');
        address owner = vm.envAddress('AUCTION_EXECUTOR_OWNER');

        vm.startBroadcast(); // Start broadcasting transactions

        address auctionExecutor = address(new AuctionExecutor(owner, ltv));

        console.log('AuctionExecutor deployed at: ', auctionExecutor);

        vm.stopBroadcast(); 
    }
}