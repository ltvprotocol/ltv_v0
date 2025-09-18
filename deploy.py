"""
Deployment Orchestrator for LTV Protocol Contracts
"""

import subprocess
import sys
import argparse
import os
import json
import re

from enum import Enum

class CONTRACTS(Enum):
    ERC20_MODULE = "ERC20_MODULE"
    BORROW_VAULT_MODULE = "BORROW_VAULT_MODULE"
    COLLATERAL_VAULT_MODULE = "COLLATERAL_VAULT_MODULE"
    LOW_LEVEL_REBALANCE_MODULE = "LOW_LEVEL_REBALANCE_MODULE"
    AUCTION_MODULE = "AUCTION_MODULE"
    ADMINISTRATION_MODULE = "ADMINISTRATION_MODULE"
    INITIALIZE_MODULE = "INITIALIZE_MODULE"
    MODULES_PROVIDER = "MODULES_PROVIDER"
    LTV = "LTV"
    BEACON = "BEACON"
    WHITELIST_REGISTRY = "WHITELIST_REGISTRY"
    VAULT_BALANCE_AS_LENDING_CONNECTOR = "VAULT_BALANCE_AS_LENDING_CONNECTOR"
    SLIPPAGE_CONNECTOR = "SLIPPAGE_CONNECTOR"
    ORACLE_CONNECTOR = "ORACLE_CONNECTOR"
    LENDING_CONNECTOR = "LENDING_CONNECTOR"
    LTV_BEACON_PROXY = "LTV_BEACON_PROXY"
    GHOST_UPGRADE = "GHOST_UPGRADE"

CHAIN_TO_CHAIN_ID = {
    "mainnet": 1,
    "sepolia": 11155111,
    "local_fork_mainnet": 1,
    "local_fork_sepolia": 11155111,
    "local": 31337,
}

def get_contract_to_deploy_file(lending_protocol, contract):
    """Returns the deployment file for a specific contract based on the lending protocol"""
    base_mapping = {
        CONTRACTS.ERC20_MODULE: "script/ltv_elements/DeployERC20Module.s.sol",
        CONTRACTS.BORROW_VAULT_MODULE: "script/ltv_elements/DeployBorrowVaultModule.s.sol",
        CONTRACTS.COLLATERAL_VAULT_MODULE: "script/ltv_elements/DeployCollateralVaultModule.s.sol",
        CONTRACTS.LOW_LEVEL_REBALANCE_MODULE: "script/ltv_elements/DeployLowLevelRebalanceModule.s.sol",
        CONTRACTS.AUCTION_MODULE: "script/ltv_elements/DeployAuctionModule.s.sol",
        CONTRACTS.ADMINISTRATION_MODULE: "script/ltv_elements/DeployAdministrationModule.s.sol",
        CONTRACTS.INITIALIZE_MODULE: "script/ltv_elements/DeployInitializeModule.s.sol",
        CONTRACTS.MODULES_PROVIDER: "script/ltv_elements/DeployModulesProvider.s.sol",
        CONTRACTS.LTV: "script/ltv_elements/DeployLTV.s.sol",
        CONTRACTS.BEACON: "script/ltv_elements/DeployBeacon.s.sol",
        CONTRACTS.WHITELIST_REGISTRY: "script/ltv_elements/DeployWhitelistRegistry.s.sol",
        CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR: "script/ltv_elements/DeployVaultBalanceAsLendingConnector.s.sol",
        CONTRACTS.SLIPPAGE_CONNECTOR: "script/ltv_elements/DeployConstantSlippageConnector.s.sol",
        CONTRACTS.LTV_BEACON_PROXY: "script/ltv_elements/DeployLTVBeaconProxy.s.sol",
        CONTRACTS.GHOST_UPGRADE: "script/ghost/DeployGhostUpgrade.s.sol:DeployGhostUpgrade",
    }
    
    # Handle protocol-specific connectors
    if contract == CONTRACTS.ORACLE_CONNECTOR:
        if lending_protocol == "aave":
            return "script/aave/DeployAaveOracleConnector.s.sol"
        elif lending_protocol == "morpho":
            return "script/morpho/DeployMorphoOracleConnector.s.sol"
        elif lending_protocol == "ghost":
            return "script/ghost/DeployOracleConnector.s.sol"
        else:
            print(f"ERROR Unsupported lending protocol: {lending_protocol}")
            print("Supported protocols: aave, morpho")
            sys.exit(1)
    elif contract == CONTRACTS.LENDING_CONNECTOR:
        if lending_protocol == "aave":
            return "script/aave/DeployAaveLendingConnector.s.sol"
        elif lending_protocol == "morpho":
            return "script/morpho/DeployMorphoLendingConnector.s.sol"
        elif lending_protocol == "ghost":
            return "script/ghost/DeployLendingConnector.s.sol"
        else:
            print(f"ERROR Unsupported lending protocol: {lending_protocol}")
            print("Supported protocols: aave, morpho")
            sys.exit(1)
    
    # Return base mapping for non-protocol-specific contracts
    return base_mapping[contract]

def get_rpc_url(chain):
    if chain == "mainnet":
        return os.getenv("RPC_MAINNET")
    elif chain == "sepolia":
        return os.getenv("RPC_SEPOLIA")
    elif chain == "local_fork_mainnet" or chain == "local" or chain == "local_fork_sepolia":
        return "localhost:8545"
    else:
        print(f"ERROR Invalid chain: {chain}")
        sys.exit(1)

def need_verify(chain):
    return chain != "local_fork_mainnet" and chain != "local" and chain != "local_fork_sepolia"

def get_latest_receipt_contract_address(chain, contract, lending_protocol):
    deploy_file = get_contract_to_deploy_file(lending_protocol, contract)
    deploy_file_name = deploy_file.split("/")[-1]
    latest_receipt_file = f"broadcast/{deploy_file_name}/{CHAIN_TO_CHAIN_ID[chain]}/run-latest.json"
    
    with open(latest_receipt_file, "r") as f:
        data = json.load(f)
        return data["transactions"][-1]["contractAddress"]

def get_expected_address(chain, contract, lending_protocol, args = {}):
    res = run_script(chain, contract, lending_protocol, {}, args)

    # Look for the line with "Expected address:  0x..."
    match = re.search(r"Expected address:\s+(0x[a-fA-F0-9]{40})", res)
    if match:
        expected_address = match.group(1)
        return expected_address
    else:
        print(res)
        print("ERROR Could not find expected address in output")
        sys.exit(1)

def get_deployed_contracts_file_path(chain, lending_protocol, args_filename):
    return f"deploy_out/{chain}/{lending_protocol}/deployed_contracts_{args_filename}"

def get_args_file_path(chain, lending_protocol, args_filename):
    return f"deploy/{chain}/{lending_protocol}/{args_filename}"

def get_contract_is_deployed(chain, contract, lending_protocol, args_filename, args = {}):
    expected_address = get_expected_address(chain, contract, lending_protocol, args)
    deployed_contracts_file_path = get_deployed_contracts_file_path(chain, lending_protocol, args_filename)
    if not os.path.exists(deployed_contracts_file_path):
        return False
    
    with open(deployed_contracts_file_path, "r") as f:
        data = json.load(f)
        return contract.value in data and data[contract.value].lower() == expected_address.lower()  

def run_script(chain, contract, lending_protocol, private_key = {}, args = {}):
    deploy_file = get_contract_to_deploy_file(lending_protocol, contract)
    env = os.environ.copy()
    for k, v in args.items():
        env[str(k)] = str(v)
        
    private_key_part = []
    if private_key:
        private_key_part.append("--private-key")
        private_key_part.append(private_key)
        env["DEPLOY"] = "true"
        private_key_part.append("--broadcast")
        if (need_verify(chain)):
            private_key_part.append("--verify")
            
    else:
        env["DEPLOY"] = "false"
        
    rpc_url = get_rpc_url(chain)
    result = subprocess.run(["forge", "script", deploy_file, "--rpc-url", rpc_url, "-vv"] + private_key_part, env=env, text=True, capture_output=True)
    
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        print("ERROR Error running script")
        sys.exit(1)
    
    return result.stdout

def deploy_contract(chain, contract, lending_protocol, private_key, args = {}):
    res = run_script(chain, contract, lending_protocol, private_key, args)
    
    match = re.search(r"Contract already deployed at:\s+(0x[a-fA-F0-9]{40})", res)
    if match:
        return match.group(1)
    else:
        return get_latest_receipt_contract_address(chain, contract, lending_protocol)

def ensure_deployed_contracts_file_exists(chain, lending_protocol, args_filename):
    deploy_file_path = get_deployed_contracts_file_path(chain, lending_protocol, args_filename)
    if not os.path.exists(deploy_file_path):
        # Create the deploy directory if it doesn't exist
        deploy_dir = os.path.dirname(deploy_file_path)
        os.makedirs(deploy_dir, exist_ok=True)
        # Write a simple deploy.json file as a placeholder
        with open(deploy_file_path, "w") as f:
            json.dump({}, f)

def write_to_deploy_file(contract, chain, lending_protocol, deployed_address, args_filename, args = {}):
    ensure_deployed_contracts_file_exists(chain, lending_protocol, args_filename)
    
    deployed_contracts_file_path = get_deployed_contracts_file_path(chain, lending_protocol, args_filename)
    with open(deployed_contracts_file_path, "r") as f:
        data = json.load(f)
        data[contract.value] = deployed_address
    
    with open(deployed_contracts_file_path, "w") as f:
        json.dump(data, f, indent=4)

    expected_address = get_expected_address(chain, contract, lending_protocol, args)
    if not deployed_address.lower() == expected_address.lower():
        print(f"ERROR Deployed address {deployed_address} does not match expected address {expected_address}")
        sys.exit(1)


def deploy_erc20_module(chain, lending_protocol, private_key, args_filename):
    if get_contract_is_deployed(chain, CONTRACTS.ERC20_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS ERC20 module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.ERC20_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.ERC20_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS ERC20 module deployed at {deployed_address}")

def deploy_borrow_vault_module(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.ERC20_MODULE, lending_protocol, args_filename):
        print(f"ERROR ERC20 module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.BORROW_VAULT_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS Borrow vault module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.BORROW_VAULT_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.BORROW_VAULT_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS Borrow vault module deployed at {deployed_address}")

def deploy_collateral_vault_module(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.BORROW_VAULT_MODULE, lending_protocol, args_filename):
        print(f"ERROR Borrow vault module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.COLLATERAL_VAULT_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS Collateral vault module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.COLLATERAL_VAULT_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.COLLATERAL_VAULT_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS Collateral vault module deployed at {deployed_address}")

def deploy_low_level_rebalance_module(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.COLLATERAL_VAULT_MODULE, lending_protocol, args_filename):
        print(f"ERROR Collateral vault module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.LOW_LEVEL_REBALANCE_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS Low level rebalance module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.LOW_LEVEL_REBALANCE_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.LOW_LEVEL_REBALANCE_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS Low level rebalance module deployed at {deployed_address}")

def deploy_auction_module(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.LOW_LEVEL_REBALANCE_MODULE, lending_protocol, args_filename):
        print(f"ERROR Low level rebalance module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.AUCTION_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS Auction module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.AUCTION_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.AUCTION_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS Auction module deployed at {deployed_address}")

def deploy_administration_module(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.AUCTION_MODULE, lending_protocol, args_filename):
        print(f"ERROR Auction module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.ADMINISTRATION_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS Administration module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.ADMINISTRATION_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.ADMINISTRATION_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS Administration module deployed at {deployed_address}")

def deploy_initialize_module(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.ADMINISTRATION_MODULE, lending_protocol, args_filename):
        print(f"ERROR Administration module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.INITIALIZE_MODULE, lending_protocol, args_filename):
        print(f"SUCCESS Initialize module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.INITIALIZE_MODULE, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.INITIALIZE_MODULE, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS Initialize module deployed at {deployed_address}")

def deploy_modules_provider(chain, lending_protocol, private_key, args_filename):
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    if not get_contract_is_deployed(chain, CONTRACTS.ADMINISTRATION_MODULE, lending_protocol, args_filename):
        print(f"ERROR Administration module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.MODULES_PROVIDER, lending_protocol, args_filename, data):
        print(f"SUCCESS Modules provider already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.MODULES_PROVIDER, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.MODULES_PROVIDER, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Modules provider deployed at {deployed_address}")

def deploy_ltv(chain, lending_protocol, private_key, args_filename):
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    if not get_contract_is_deployed(chain, CONTRACTS.MODULES_PROVIDER, lending_protocol, args_filename, data):
        print(f"ERROR Modules provider must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.LTV, lending_protocol, args_filename):
        print(f"SUCCESS LTV already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.LTV, lending_protocol, private_key)
    write_to_deploy_file(CONTRACTS.LTV, chain, lending_protocol, deployed_address, args_filename)
    print(f"SUCCESS LTV deployed at {deployed_address}")

def deploy_beacon(chain, lending_protocol, private_key, args_filename):
    if not get_contract_is_deployed(chain, CONTRACTS.LTV, lending_protocol, args_filename):
        print(f"ERROR LTV must be deployed first")
        sys.exit(1)
        
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)

    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))
    
    if get_contract_is_deployed(chain, CONTRACTS.BEACON, lending_protocol, args_filename, data):
        print(f"SUCCESS Beacon already deployed")
        return

    deployed_address = deploy_contract(chain, CONTRACTS.BEACON, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.BEACON, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Beacon deployed at {deployed_address}")

def  deploy_whitelist_registry(chain, lending_protocol, private_key, args_filename, contract = CONTRACTS.BEACON):
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))

    if not get_contract_is_deployed(chain, contract, lending_protocol, args_filename, data):
        print(f"ERROR {contract.value} must be deployed first")
        sys.exit(1)

    if get_contract_is_deployed(chain, CONTRACTS.WHITELIST_REGISTRY, lending_protocol, args_filename, data):
        print(f"SUCCESS Whitelist registry already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.WHITELIST_REGISTRY, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.WHITELIST_REGISTRY, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Whitelist registry deployed at {deployed_address}")

def deploy_vault_balance_as_lending_connector(chain, lending_protocol, private_key, args_filename):
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))
    
    if not get_contract_is_deployed(chain, CONTRACTS.WHITELIST_REGISTRY, lending_protocol, args_filename, data):
        print(f"ERROR Whitelist registry must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR, lending_protocol, args_filename, data):
        print(f"SUCCESS Vault balance as lending connector already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Vault balance as lending connector deployed at {deployed_address}")

def deploy_constant_slippage_connector(chain, lending_protocol, private_key, args_filename):
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)

    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))

    if not get_contract_is_deployed(chain, CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR, lending_protocol, args_filename, data):
        print(f"ERROR Vault balance as lending connector must be deployed first")
        sys.exit(1)

    if get_contract_is_deployed(chain, CONTRACTS.SLIPPAGE_CONNECTOR, lending_protocol, args_filename, data):
        print(f"SUCCESS Constant slippage connector already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.SLIPPAGE_CONNECTOR, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.SLIPPAGE_CONNECTOR, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Constant slippage connector deployed at {deployed_address}")

def deploy_oracle_connector(chain, lending_protocol, private_key, args_filename, contract = CONTRACTS.BEACON):
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))
    
    if not get_contract_is_deployed(chain, contract, lending_protocol, args_filename, data):
        print(f"ERROR {contract} must be deployed first")
        sys.exit(1) 

    if get_contract_is_deployed(chain, CONTRACTS.ORACLE_CONNECTOR, lending_protocol, args_filename, data):
        print(f"SUCCESS Oracle connector already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.ORACLE_CONNECTOR, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.ORACLE_CONNECTOR, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Oracle connector deployed at {deployed_address}")

def deploy_lending_connector(chain, lending_protocol, private_key, args_filename, contract = CONTRACTS.ORACLE_CONNECTOR):    
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))

    if not get_contract_is_deployed(chain, contract, lending_protocol, args_filename, data):
        print(f"ERROR {contract.value} must be deployed first")
        sys.exit(1)

    if get_contract_is_deployed(chain, CONTRACTS.LENDING_CONNECTOR, lending_protocol, args_filename, data):
        print(f"SUCCESS Lending connector already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.LENDING_CONNECTOR, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.LENDING_CONNECTOR, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS Lending connector deployed at {deployed_address}")

def deploy_ltv_beacon_proxy(chain, lending_protocol, private_key, args_filename):
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))

    if not get_contract_is_deployed(chain, CONTRACTS.LENDING_CONNECTOR, lending_protocol, args_filename, data):
        print(f"ERROR Lending connector must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.LTV_BEACON_PROXY, lending_protocol, args_filename, data):
        print(f"SUCCESS LTV beacon proxy already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.LTV_BEACON_PROXY, lending_protocol, private_key, data)
    write_to_deploy_file(CONTRACTS.LTV_BEACON_PROXY, chain, lending_protocol, deployed_address, args_filename, data)
    print(f"SUCCESS LTV beacon proxy deployed at {deployed_address}")

def upgrade_ghost(chain, lending_protocol, private_key, args_filename):
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
        
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))
    
    if not get_contract_is_deployed(chain, CONTRACTS.SLIPPAGE_CONNECTOR, lending_protocol, args_filename, data):
        print(f"ERROR Slippage connector must be deployed first")
        sys.exit(1)
    
    run_script(chain, CONTRACTS.GHOST_UPGRADE, lending_protocol, private_key, data)
    print(f"SUCCESS Ghost upgrade is successful")


def test_deployed_ltv_beacon_proxy(chain, lending_protocol, args_filename):
    with open(get_deployed_contracts_file_path(chain, lending_protocol, args_filename), "r") as f:
        data = json.load(f)
    
    env = os.environ.copy()
    env["LTV_BEACON_PROXY"] = data["LTV_BEACON_PROXY"]

    result = subprocess.run(["forge", "script", "script/ltv_elements/TestDeployedLTVBeaconProxy.s.sol"], env=env, text=True, capture_output=True)

    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        print("ERROR Error testing deployed LTV beacon proxy")
        sys.exit(1)
    print(f"SUCCESS LTV beacon proxy test passed")    

def main():
    parser = argparse.ArgumentParser(description="Foundry Script")
    parser.add_argument('--full-deploy', help='Full ltv protocol deployment', action='store_true')
    parser.add_argument('--chain', help='Chain to deploy to. Possible values: mainnet, local-fork-mainnet, local-fork-sepolia, sepolia', required=True)
    parser.add_argument('--lending-protocol', help='Lending protocol to deploy for. Possible values: aave, ghost, morpho', required=True)
    parser.add_argument('--args-filename', help='Name of the args file, stored in the deploy/(chain)/(lending_protocol) folder', required=True)
    parser.add_argument('--etherscan-api-key', help='Etherscan API key')
    parser.add_argument('--deploy-erc20-module', help='Deploy ERC20 module', action='store_true')
    parser.add_argument('--deploy-borrow-vault-module', help='Deploy Borrow vault module', action='store_true')
    parser.add_argument('--deploy-collateral-vault-module', help='Deploy Collateral vault module', action='store_true')
    parser.add_argument('--deploy-low-level-rebalance-module', help='Deploy Low level rebalance module', action='store_true')
    parser.add_argument('--deploy-auction-module', help='Deploy Auction module', action='store_true')
    parser.add_argument('--deploy-administration-module', help='Deploy Administration module', action='store_true')
    parser.add_argument('--deploy-initialize-module', help='Deploy Initialize module', action='store_true')
    parser.add_argument('--deploy-modules-provider', help='Deploy Modules provider', action='store_true')
    parser.add_argument('--deploy-ltv', help='Deploy LTV', action='store_true')
    parser.add_argument('--deploy-beacon', help='Deploy Beacon', action='store_true')
    parser.add_argument('--deploy-whitelist-registry', help='Deploy Whitelist registry', action='store_true')
    parser.add_argument('--deploy-vault-balance-as-lending-connector', help='Deploy Vault balance as lending connector', action='store_true')
    parser.add_argument('--deploy-constant-slippage-connector', help='Deploy Constant slippage connector', action='store_true')
    parser.add_argument('--deploy-oracle-connector', help='Deploy Oracle connector', action='store_true')
    parser.add_argument('--deploy-lending-connector', help='Deploy Lending connector', action='store_true')
    parser.add_argument('--deploy-ltv-beacon-proxy', help='Deploy LTV beacon proxy', action='store_true')
    parser.add_argument('--test-deployed-ltv-beacon-proxy', help='Test deployed LTV beacon proxy', action='store_true')
    parser.add_argument('--upgrade-ghost', help='Upgrade ghost testnet', action='store_true')
    parser.add_argument('--private-key', help='Private key to use for deployment (can also be set via PRIVATE_KEY env var)')

    args = parser.parse_args()

    # Check for private key from environment variable if not provided as argument
    if not args.private_key:
        args.private_key = os.getenv('PRIVATE_KEY')
        if not args.private_key:
            print("ERROR Private key must be provided either via --private-key argument or PRIVATE_KEY environment variable")
            sys.exit(1)

    if need_verify(args.chain) and not os.getenv("ETHERSCAN_API_KEY"):
        if not args.etherscan_api_key:
            print("ERROR Etherscan API key must be provided via --etherscan-api-key argument or ETHERSCAN_API_KEY environment variable")
            sys.exit(1)
        else:
            os.environ["ETHERSCAN_API_KEY"] = args.etherscan_api_key

    if args.deploy_erc20_module:
        deploy_erc20_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_borrow_vault_module:
        deploy_borrow_vault_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_collateral_vault_module:
        deploy_collateral_vault_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_low_level_rebalance_module:
        deploy_low_level_rebalance_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_auction_module:
        deploy_auction_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_administration_module:
        deploy_administration_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_initialize_module:
        deploy_initialize_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_modules_provider:
        deploy_modules_provider(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_ltv:
        deploy_ltv(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_beacon:
        deploy_beacon(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_whitelist_registry:
        deploy_whitelist_registry(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_vault_balance_as_lending_connector:
        deploy_vault_balance_as_lending_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_constant_slippage_connector:
        deploy_constant_slippage_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_oracle_connector:
        deploy_oracle_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_lending_connector:
        deploy_lending_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.deploy_ltv_beacon_proxy:
        deploy_ltv_beacon_proxy(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.full_deploy:
        deploy_erc20_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_borrow_vault_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_collateral_vault_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_low_level_rebalance_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_auction_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_administration_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_initialize_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_modules_provider(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_ltv(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_beacon(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_whitelist_registry(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_vault_balance_as_lending_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_constant_slippage_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_oracle_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_lending_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_ltv_beacon_proxy(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.upgrade_ghost:
        deploy_erc20_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_borrow_vault_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_collateral_vault_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_low_level_rebalance_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_auction_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_administration_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_initialize_module(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_modules_provider(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_ltv(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_whitelist_registry(args.chain, args.lending_protocol, args.private_key, args.args_filename, CONTRACTS.LTV)
        deploy_vault_balance_as_lending_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_constant_slippage_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        deploy_oracle_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename, CONTRACTS.SLIPPAGE_CONNECTOR)
        deploy_lending_connector(args.chain, args.lending_protocol, args.private_key, args.args_filename)
        upgrade_ghost(args.chain, args.lending_protocol, args.private_key, args.args_filename)

    if args.test_deployed_ltv_beacon_proxy:
        test_deployed_ltv_beacon_proxy(args.chain, args.lending_protocol, args.args_filename)

if __name__ == "__main__":
    main()
