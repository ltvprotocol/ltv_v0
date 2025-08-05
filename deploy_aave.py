"""
Simple Foundry Build Script
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
    SLIPPAGE_CONNECTOR = "SLIPPAGE_CONNECTOR"
    ORACLE_CONNECTOR = "ORACLE_CONNECTOR"
    LENDING_CONNECTOR = "LENDING_CONNECTOR"
    WHITELIST_REGISTRY = "WHITELIST_REGISTRY"
    LTV_BEACON_PROXY = "LTV_BEACON_PROXY"
    
CONTRACT_TO_DEPLOY_FILE = {
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
    CONTRACTS.SLIPPAGE_CONNECTOR: "script/ltv_elements/DeployConstantSlippageConnector.s.sol",
}

CHAIN_TO_CHAIN_ID = {
    "mainnet": 1,
    "sepolia": 11155111,
    "local": 31337,
}

def get_rpc_url(chain):
    if chain == "mainnet":
        return os.getenv("RPC_MAINNET")
    elif chain == "sepolia":
        return os.getenv("RPC_SEPOLIA")
    elif chain == "local":
        return "localhost:8545"
    else:
        print(f"❌ Invalid chain: {chain}")
        sys.exit(1)


def get_latest_receipt_contract_address(chain, contract):
    deploy_file_name = CONTRACT_TO_DEPLOY_FILE[contract].split("/")[-1]
    latest_receipt_file = f"broadcast/{deploy_file_name}/{CHAIN_TO_CHAIN_ID[chain]}/run-latest.json"
    
    with open(latest_receipt_file, "r") as f:
        data = json.load(f)
        return data["transactions"][-1]["contractAddress"]

def get_expected_address(chain, deploy_file, args = {}):
    args["DEPLOY"] = False
    env = os.environ.copy()
    for k, v in args.items():
        env[str(k)] = str(v)
    
    rpc_url = get_rpc_url(chain)

    # The subprocess.run above does not capture output, so let's use subprocess.Popen to capture stdout
    result = subprocess.run(
        ["forge", "script", deploy_file, "--rpc-url", rpc_url, "-vv"],
        env=env,
        capture_output=True,
        text=True
    )

    # Look for the line with "Expected address:  0x..."
    match = re.search(r"Expected address:\s+(0x[a-fA-F0-9]{40})", result.stdout)
    if match:
        expected_address = match.group(1)
        return expected_address
    else:
        print(result.stdout)
        print(result.stderr)
        print("❌ Could not find expected address in output")
        sys.exit(1)

def get_deployed_contracts_file_path(chain):
    return f"deploy/{chain}/aave/deployed_contracts.json"

def get_args_file_path(chain, args_filename):
    return f"deploy/{chain}/aave/{args_filename}"

def get_contract_is_deployed(chain, contract, args = {}):
    expected_address = get_expected_address(chain, CONTRACT_TO_DEPLOY_FILE[contract], args)
    deployed_contracts_file_path = get_deployed_contracts_file_path(chain)
    if not os.path.exists(deployed_contracts_file_path):
        return False
    
    with open(deployed_contracts_file_path, "r") as f:
        data = json.load(f)
        return contract.value in data and data[contract.value].lower() == expected_address.lower()  


def deploy_contract(chain, contract, private_key, args = {}):
    deploy_file = CONTRACT_TO_DEPLOY_FILE[contract]
    args["DEPLOY"] = True
    if not os.path.exists(deploy_file):
        print(f"❌ Contract path {deploy_file} does not exist")
        sys.exit(1)
        
    env = os.environ.copy()
    
    for k, v in args.items():
        env[str(k)] = str(v)
        
    rpc_url = get_rpc_url(chain)
    
    vefity_part = f"--verify --etherscan-api-key {os.getenv('ETHERSCAN_API_KEY')}" if chain != "local" else ""
    
    result = subprocess.run(["forge", "script", deploy_file, "--rpc-url", rpc_url, "--broadcast", vefity_part, "--private-key", private_key], env=env, text=True, capture_output=True)
    
    match = re.search(r"Contract already deployed at:\s+(0x[a-fA-F0-9]{40})", result.stdout)
    if match:
        return match.group(1)
    else:
        return get_latest_receipt_contract_address(chain, contract)

def ensure_deployed_contracts_file_exists(chain):
    deploy_file_path = get_deployed_contracts_file_path(chain)
    if not os.path.exists(deploy_file_path):
        # Create the deploy directory if it doesn't exist
        deploy_dir = os.path.dirname(deploy_file_path)
        os.makedirs(deploy_dir, exist_ok=True)
        # Write a simple deploy.json file as a placeholder
        deployed_contracts_json_path = os.path.join(deploy_dir, "deployed_contracts.json")
        with open(deployed_contracts_json_path, "w") as f:
            json.dump({}, f)

def write_to_deploy_file(contract, chain, deployed_address, args = {}):
    ensure_deployed_contracts_file_exists(chain)
    
    deployed_contracts_file_path = get_deployed_contracts_file_path(chain)
    with open(deployed_contracts_file_path, "r") as f:
        data = json.load(f)
        data[contract.value] = deployed_address
    
    with open(deployed_contracts_file_path, "w") as f:
        json.dump(data, f, indent=4)

    expected_address = get_expected_address(chain, CONTRACT_TO_DEPLOY_FILE[contract], args)
    if not deployed_address.lower() == expected_address.lower():
        print(f"❌ Deployed address {deployed_address} does not match expected address {expected_address}")
        sys.exit(1)
 

def deploy_erc20_module(chain, private_key):
    if get_contract_is_deployed(chain, CONTRACTS.ERC20_MODULE):
        print(f"✅ ERC20 module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.ERC20_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.ERC20_MODULE, chain, deployed_address)
    print(f"✅ ERC20 module deployed at {deployed_address}")

def deploy_borrow_vault_module(chain, private_key):
    if not get_contract_is_deployed(chain, CONTRACTS.ERC20_MODULE):
        print(f"❌ ERC20 module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.BORROW_VAULT_MODULE):
        print(f"✅ Borrow vault module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.BORROW_VAULT_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.BORROW_VAULT_MODULE, chain, deployed_address)
    print(f"✅ Borrow vault module deployed at {deployed_address}")

def deploy_collateral_vault_module(chain, private_key):
    if not get_contract_is_deployed(chain, CONTRACTS.BORROW_VAULT_MODULE):
        print(f"❌ Borrow vault module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.COLLATERAL_VAULT_MODULE):
        print(f"✅ Collateral vault module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.COLLATERAL_VAULT_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.COLLATERAL_VAULT_MODULE, chain, deployed_address)
    print(f"✅ Collateral vault module deployed at {deployed_address}")

def deploy_low_level_rebalance_module(chain, private_key):
    if not get_contract_is_deployed(chain, CONTRACTS.COLLATERAL_VAULT_MODULE):
        print(f"❌ Collateral vault module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.LOW_LEVEL_REBALANCE_MODULE):
        print(f"✅ Low level rebalance module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.LOW_LEVEL_REBALANCE_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.LOW_LEVEL_REBALANCE_MODULE, chain, deployed_address)
    print(f"✅ Low level rebalance module deployed at {deployed_address}")

def deploy_auction_module(chain, private_key):
    if not get_contract_is_deployed(chain, CONTRACTS.LOW_LEVEL_REBALANCE_MODULE):
        print(f"❌ Low level rebalance module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.AUCTION_MODULE):
        print(f"✅ Auction module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.AUCTION_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.AUCTION_MODULE, chain, deployed_address)
    print(f"✅ Auction module deployed at {deployed_address}")

def deploy_administration_module(chain, private_key):
    if not get_contract_is_deployed(chain, CONTRACTS.AUCTION_MODULE):
        print(f"❌ Auction module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.ADMINISTRATION_MODULE):
        print(f"✅ Administration module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.ADMINISTRATION_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.ADMINISTRATION_MODULE, chain, deployed_address)
    print(f"✅ Administration module deployed at {deployed_address}")

def deploy_initialize_module(chain, private_key):
    if not get_contract_is_deployed(chain, CONTRACTS.ADMINISTRATION_MODULE):
        print(f"❌ Administration module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.INITIALIZE_MODULE):
        print(f"✅ Initialize module already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.INITIALIZE_MODULE, private_key)
    write_to_deploy_file(CONTRACTS.INITIALIZE_MODULE, chain, deployed_address)
    print(f"✅ Initialize module deployed at {deployed_address}")

def deploy_modules_provider(chain, private_key):
    with open(get_deployed_contracts_file_path(chain), "r") as f:
        data = json.load(f)
    if not get_contract_is_deployed(chain, CONTRACTS.ADMINISTRATION_MODULE):
        print(f"❌ Administration module must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.MODULES_PROVIDER, data):
        print(f"✅ Modules provider already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.MODULES_PROVIDER, private_key, data)
    write_to_deploy_file(CONTRACTS.MODULES_PROVIDER, chain, deployed_address, data)
    print(f"✅ Modules provider deployed at {deployed_address}")

def deploy_ltv(chain, private_key):
    with open(get_deployed_contracts_file_path(chain), "r") as f:
        data = json.load(f)
    if not get_contract_is_deployed(chain, CONTRACTS.MODULES_PROVIDER, data):
        print(f"❌ Modules provider must be deployed first")
        sys.exit(1)
    
    if get_contract_is_deployed(chain, CONTRACTS.LTV):
        print(f"✅ LTV already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.LTV, private_key)
    write_to_deploy_file(CONTRACTS.LTV, chain, deployed_address)
    print(f"✅ LTV deployed at {deployed_address}")

def deploy_beacon(chain, private_key, args):
    if not get_contract_is_deployed(chain, CONTRACTS.LTV):
        print(f"❌ LTV must be deployed first")
        sys.exit(1)
        
    with open(get_args_file_path(chain, args), "r") as f:
        data = json.load(f)

    with open(get_deployed_contracts_file_path(chain), "r") as f:
        data.update(json.load(f))
    
    if get_contract_is_deployed(chain, CONTRACTS.BEACON, data):
        print(f"✅ Beacon already deployed")
        return

    deployed_address = deploy_contract(chain, CONTRACTS.BEACON, private_key, data)
    write_to_deploy_file(CONTRACTS.BEACON, chain, deployed_address, data)
    print(f"✅ Beacon deployed at {deployed_address}")

def deploy_constant_slippage_connector(chain, private_key, args_filename):
    with open(get_args_file_path(chain, args_filename), "r") as f:
        data = json.load(f)

    with open(get_deployed_contracts_file_path(chain), "r") as f:
        data.update(json.load(f))

    if not get_contract_is_deployed(chain, CONTRACTS.BEACON, data):
        print(f"❌ Beacon must be deployed first")
        sys.exit(1)

    if get_contract_is_deployed(chain, CONTRACTS.SLIPPAGE_CONNECTOR, data):
        print(f"✅ Constant slippage connector already deployed")
        return
    
    deployed_address = deploy_contract(chain, CONTRACTS.SLIPPAGE_CONNECTOR, private_key, data)
    write_to_deploy_file(CONTRACTS.SLIPPAGE_CONNECTOR, chain, deployed_address, data)
    print(f"✅ Constant slippage connector deployed at {deployed_address}")

def main():
    parser = argparse.ArgumentParser(description="Foundry Script")
    parser.add_argument('--full-deploy', help='Full ltv protocol deployment', action='store_true')
    parser.add_argument('--chain', help='Chain to deploy to. Possible values: mainnet, sepolia, local', required=True)
    parser.add_argument('--args-filename', help='Name of the args file, stored in the deploy/(chain)/aave folder')
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
    parser.add_argument('--deploy-constant-slippage-connector', help='Deploy Constant slippage connector', action='store_true')
    parser.add_argument('--private-key', help='Private key to use for deployment (can also be set via PRIVATE_KEY env var)')
    
    # parser.add_argument('--build', action='store_true', help='Run forge build')
    # parser.add_argument('--test', action='store_true', help='Run forge test')
    # parser.add_argument('--clean', action='store_true', help='Clean before building')
    
    args = parser.parse_args()
    
    # Check for private key from environment variable if not provided as argument
    if not args.private_key:
        args.private_key = os.getenv('PRIVATE_KEY')
        if not args.private_key:
            print("❌ Private key must be provided either via --private-key argument or PRIVATE_KEY environment variable")
            sys.exit(1)
    
    if args.full_deploy:
        if not args.args_filename:
            print("❌ --args-filename must be provided when using --full-deploy")
            sys.exit(1)
    
    if args.deploy_erc20_module:
        deploy_erc20_module(args.chain, args.private_key)
    
    if args.deploy_borrow_vault_module:
        deploy_borrow_vault_module(args.chain, args.private_key)
    
    if args.deploy_collateral_vault_module:
        deploy_collateral_vault_module(args.chain, args.private_key)
    
    if args.deploy_low_level_rebalance_module:
        deploy_low_level_rebalance_module(args.chain, args.private_key)
    
    if args.deploy_auction_module:
        deploy_auction_module(args.chain, args.private_key)
    
    if args.deploy_administration_module:
        deploy_administration_module(args.chain, args.private_key)
    
    if args.deploy_initialize_module:
        deploy_initialize_module(args.chain, args.private_key)
    
    if args.deploy_modules_provider:
        deploy_modules_provider(args.chain, args.private_key)
    
    if args.deploy_ltv:
        deploy_ltv(args.chain, args.private_key)
    
    if args.deploy_beacon:
        deploy_beacon(args.chain, args.private_key, args.args_filename)
    
    if args.deploy_constant_slippage_connector:
        deploy_constant_slippage_connector(args.chain, args.private_key, args.args_filename)
    
    if args.full_deploy:
        deploy_erc20_module(args.chain, args.private_key)
        deploy_borrow_vault_module(args.chain, args.private_key)
        deploy_collateral_vault_module(args.chain, args.private_key)
        deploy_low_level_rebalance_module(args.chain, args.private_key)
        deploy_auction_module(args.chain, args.private_key)
        deploy_administration_module(args.chain, args.private_key)
        deploy_initialize_module(args.chain, args.private_key)
        deploy_modules_provider(args.chain, args.private_key)
        deploy_ltv(args.chain, args.private_key)
        deploy_beacon(args.chain, args.private_key, args.args_filename)
        deploy_constant_slippage_connector(args.chain, args.private_key, args.args_filename)
    # if args.clean:
    #     print("🧹 Cleaning build artifacts...")
    #     subprocess.run(['forge', 'clean'], check=True)
    
    # if args.build:
    #     success = success and run_command(['forge', 'build'], "Building project")
    
    # if args.test:
    #     success = success and run_command(['forge', 'test'], "Running tests")
    
    # # If no specific command given, run both build and test
    # if not args.build and not args.test:
    #     success = success and run_command(['forge', 'build'], "Building project")
    #     success = success and run_command(['forge', 'test'], "Running tests")


if __name__ == "__main__":
    main()
