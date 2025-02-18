PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
LTV=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318

WALLET_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
FUTURE_BORROW=$(cast call --rpc-url localhost:8545 ${LTV} "futureBorrowAssets()")
DELTA_FUTURE_BORROW="-$FUTURE_BORROW"

FUTURE_COLLATERAL=$(cast call --rpc-url localhost:8545 ${LTV} "futureCollateralAssets()")
DELTA_FUTURE_COLLATERAL=$(cast to-int256 -- -$FUTURE_COLLATERAL)

THRESHOLD=$(echo "10^17" | bc)
THRESHOLD=$(cast to-int256 $THRESHOLD)
NEGATIVE_THRESHOLD=$(cast to-int256 -- -$THRESHOLD)

if [[ $FUTURE_BORROW > $THRESHOLD ]]; then
  collateralToken=$(cast call --rpc-url localhost:8545 ${LTV} "collateralToken()")
  collateralToken=${collateralToken:26}
  collateralToken="0x${collateralToken}"
  collateralBalance=$(cast call --rpc-url localhost:8545 ${collateralToken} "balanceOf(address)" ${WALLET_ADDRESS})
  cast send --private-key $PRIVATE_KEY --rpc-url localhost:8545 ${collateralToken} "approve(address,uint256)" ${LTV} ${collateralBalance}
  cast send --private-key $PRIVATE_KEY  --rpc-url localhost:8545 ${LTV} "executeAuctionBorrow(int256)" -- $DELTA_FUTURE_BORROW
  echo "Deposit auction terminated"
elif [[ $FUTURE_BORROW < $NEGATIVE_THRESHOLD ]]; then
  borrowToken=$(cast call --rpc-url localhost:8545 ${LTV} "borrowToken()")
  borrowToken=${borrowToken:26}
  borrowToken="0x${borrowToken}"
  borrowBalance=$(cast call --rpc-url localhost:8545 ${borrowToken} "balanceOf(address)" ${WALLET_ADDRESS})
  cast send --rpc-url --private-key $PRIVATE_KEY localhost:8545 ${borrowToken} "approve(address,uint256)" ${LTV} ${borrowBalance}
  cast send --private-key $PRIVATE_KEY --rpc-url localhost:8545 ${LTV} "executeAuctionCollateral(int256)" $DELTA_FUTURE_COLLATERAL
  echo "Withdraw auction terminated"
else
  echo "No action needed"
fi