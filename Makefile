-include .env

deploy-contract :; forge script ${contract} --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --broadcast $(if $(findstring localhost,${RPC_URL}),,--verify --etherscan-api-key ${ETHERSCAN_API_KEY}) -vvvv

deploy-weth :; $(MAKE) deploy-contract contract=script/DeployWETH.s.sol
deploy-magicETH :; $(MAKE) deploy-contract contract=script/ghost/DeployMagicETH.s.sol
deploy-spooky-oracle :; $(MAKE) deploy-contract contract=script/ghost/DeploySpookyOracle.s.sol
deploy-hodl-my-beer-lending :; $(MAKE) deploy-contract contract=script/ghost/DeployHodlMyBeerLending.s.sol
deploy-hodl-lending-connector :; $(MAKE) deploy-contract contract=script/DeployLendingConnector.s.sol:DeployHodlLendingConnector
deploy-spooky-oracle-connector :; $(MAKE) deploy-contract contract=script/DeployOracleConnector.s.sol:DeploySpookyOracleConnector
deploy-constant-slippage-provider :; $(MAKE) deploy-contract contract=script/DeployConstantSlippageProvider.s.sol
deploy-ltv-impl :; $(MAKE) deploy-contract contract=script/DeployLTV.s.sol:DeployImpl
deploy-beacon :; $(MAKE) deploy-contract contract=script/DeployLTV.s.sol:DeployBeacon
deploy-ghost-ltv :; $(MAKE) deploy-contract contract=script/DeployLTV.s.sol:DeployGhostLTV
test-ghost-upgrade :; forge script script/GhostUpgrade.s.sol:GhostUpgradeTest -vvv --rpc-url ${RPC_SEPOLIA}
ghost-upgrade :; forge script script/GhostUpgrade.s.sol:GhostUpgradeScript -vvv --rpc-url ${RPC_SEPOLIA}

deploy-whitelist-registry :; $(MAKE) deploy-contract contract=script/DeployWhitelistRegistry.s.sol