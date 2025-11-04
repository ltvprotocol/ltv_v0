"""
Deployment Orchestrator for LTV Protocol Contracts
"""

import subprocess
import sys
import argparse
import os
import json
import re
import time
from enum import Enum

TEST_USER_ADDRESS = "0xF39FD6E51AAD88F6F4CE6AB8827279CFFFB92266"
TEST_USER_PRIVATE_KEY = (
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
)


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
    UPGRADE = "UPGRADE"
    GENERAL_TEST = "GENERAL_TEST"
    LIDO_TEST = "LIDO_TEST"
    NONE = "NONE"


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
        CONTRACTS.UPGRADE: "script/UpgradeLtv.s.sol:UpgradeLtv",
        CONTRACTS.GENERAL_TEST: "script/ltv_elements/TestGeneralDeployedLTVBeaconProxy.s.sol",
        CONTRACTS.LIDO_TEST: "script/ltv_elements/TestLidoDeployedLtvBeaconProxy.s.sol",
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
    elif (
        chain == "local_fork_mainnet"
        or chain == "local"
        or chain == "local_fork_sepolia"
    ):
        return "localhost:8545"
    else:
        print(f"ERROR Invalid chain: {chain}")
        sys.exit(1)


def handle_script_result(result):
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)
        print("ERROR Error running script")
        sys.exit(1)
    return result.stdout


def get_latest_receipt_file(lending_protocol, contract, chain):
    deploy_file = get_contract_to_deploy_file(lending_protocol, contract)
    deploy_file_name = deploy_file.split("/")[-1]
    return f"broadcast/{deploy_file_name}/{CHAIN_TO_CHAIN_ID[chain]}/run-latest.json"


def get_latest_receipt_contract_address(chain, contract, lending_protocol):
    latest_receipt_file = get_latest_receipt_file(lending_protocol, contract, chain)

    with open(latest_receipt_file, "r") as f:
        data = json.load(f)
        return data["transactions"][-1]["contractAddress"]


def get_expected_address(chain, contract, lending_protocol, args={}):
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


def get_verify_addresses_helper_file_path(chain, lending_protocol, args_filename):
    args_filename = args_filename.replace(".json", "")
    return (
        f"deploy_out/{chain}/{lending_protocol}/verify_addresses_helper_{args_filename}"
    )


def get_args_file_path(chain, lending_protocol, args_filename):
    return f"deploy/{chain}/{lending_protocol}/{args_filename}"


def get_contract_is_deployed(chain, contract, lending_protocol, args_filename, args={}):
    if contract == CONTRACTS.NONE:
        return True
    expected_address = get_expected_address(chain, contract, lending_protocol, args)
    deployed_contracts_file_path = get_deployed_contracts_file_path(
        chain, lending_protocol, args_filename
    )
    if not os.path.exists(deployed_contracts_file_path):
        return False

    with open(deployed_contracts_file_path, "r") as f:
        data = json.load(f)
        return (
            contract.value in data
            and data[contract.value].lower() == expected_address.lower()
        )


def run_script(chain, contract, lending_protocol, private_key={}, args={}):
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
    else:
        env["DEPLOY"] = "false"

    rpc_url = get_rpc_url(chain)
    result = subprocess.run(
        ["forge", "script", deploy_file, "--rpc-url", rpc_url, "-vv"]
        + private_key_part,
        env=env,
        text=True,
        capture_output=True,
    )

    return handle_script_result(result)


def deploy_contract(chain, contract, lending_protocol, private_key, args={}):
    res = run_script(chain, contract, lending_protocol, private_key, args)

    match = re.search(r"Contract already deployed at:\s+(0x[a-fA-F0-9]{40})", res)
    if match:
        return match.group(1)
    else:
        return get_latest_receipt_contract_address(chain, contract, lending_protocol)


def ensure_file_exists(filename, is_json=True):
    if not os.path.exists(filename):
        # Create the deploy directory if it doesn't exist
        deploy_dir = os.path.dirname(filename)
        os.makedirs(deploy_dir, exist_ok=True)
        if not is_json:
            return
        # Write a simple deploy.json file as a placeholder
        with open(filename, "w") as f:
            json.dump({}, f)


def write_to_deploy_file(
    contract, chain, lending_protocol, deployed_address, args_filename, args={}
):
    deploy_file_path = get_deployed_contracts_file_path(
        chain, lending_protocol, args_filename
    )
    verify_addresses_helper_file_path = get_verify_addresses_helper_file_path(
        chain, lending_protocol, args_filename
    )
    ensure_file_exists(deploy_file_path)
    ensure_file_exists(verify_addresses_helper_file_path, is_json=False)

    deployed_contracts_file_path = get_deployed_contracts_file_path(
        chain, lending_protocol, args_filename
    )
    with open(deployed_contracts_file_path, "r") as f:
        data = json.load(f)
        data[contract.value] = deployed_address

    expected_address = get_expected_address(chain, contract, lending_protocol, args)
    if not deployed_address.lower() == expected_address.lower():
        print(
            f"ERROR Deployed address {deployed_address} does not match expected address {expected_address}"
        )
        sys.exit(1)

    latest_receipt_file = get_latest_receipt_file(lending_protocol, contract, chain)
    with open(latest_receipt_file, "r") as f:
        latest_data = json.load(f)
    for library in latest_data["libraries"]:
        temp = library.split(":")
        library_name = temp[1]
        library_address = temp[2]
        data[library_name] = library_address

    for additional_contract in latest_data["transactions"][0]["additionalContracts"]:
        data[additional_contract["contractName"]] = additional_contract["address"]

    with open(deployed_contracts_file_path, "w") as f:
        json.dump(data, f, indent=4)

    with open(verify_addresses_helper_file_path, "w") as f:
        f.write(
            f'tail +2 {verify_addresses_helper_file_path} | xargs -I {{}} sh -c "forge verify-contract --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url {get_rpc_url(chain)} {{}}"\n'
        )
        for value in data.values():
            f.write(f"{value}\n")


def process_deployment(
    chain,
    lending_protocol,
    private_key,
    args_filename,
    current_contract,
    previous_contract=CONTRACTS.NONE,
):
    data = read_data(chain, lending_protocol, args_filename)

    if not get_contract_is_deployed(
        chain, previous_contract, lending_protocol, args_filename, data
    ):
        print(f"ERROR {previous_contract.value} must be deployed first")
        sys.exit(1)

    if get_contract_is_deployed(
        chain, current_contract, lending_protocol, args_filename, data
    ):
        print(f"SUCCESS {current_contract.value} already deployed")
        return

    deployed_address = deploy_contract(
        chain, current_contract, lending_protocol, private_key, data
    )
    write_to_deploy_file(
        current_contract,
        chain,
        lending_protocol,
        deployed_address,
        args_filename,
        data,
    )
    print(f"SUCCESS {current_contract.value} deployed at {deployed_address}")


def deploy_erc20_module(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain, lending_protocol, private_key, args_filename, CONTRACTS.ERC20_MODULE
    )


def deploy_borrow_vault_module(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.BORROW_VAULT_MODULE,
        CONTRACTS.ERC20_MODULE,
    )


def deploy_collateral_vault_module(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.COLLATERAL_VAULT_MODULE,
        CONTRACTS.BORROW_VAULT_MODULE,
    )


def deploy_low_level_rebalance_module(
    chain, lending_protocol, private_key, args_filename
):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.LOW_LEVEL_REBALANCE_MODULE,
        CONTRACTS.COLLATERAL_VAULT_MODULE,
    )


def deploy_auction_module(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.AUCTION_MODULE,
        CONTRACTS.LOW_LEVEL_REBALANCE_MODULE,
    )


def deploy_administration_module(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.ADMINISTRATION_MODULE,
        CONTRACTS.AUCTION_MODULE,
    )


def deploy_initialize_module(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.INITIALIZE_MODULE,
        CONTRACTS.ADMINISTRATION_MODULE,
    )


def deploy_modules_provider(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.MODULES_PROVIDER,
        CONTRACTS.INITIALIZE_MODULE,
    )


def deploy_ltv(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.LTV,
        CONTRACTS.MODULES_PROVIDER,
    )


def deploy_beacon(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.BEACON,
        CONTRACTS.LTV,
    )


def deploy_whitelist_registry(
    chain,
    lending_protocol,
    private_key,
    args_filename,
    previous_contract=CONTRACTS.BEACON,
):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.WHITELIST_REGISTRY,
        previous_contract,
    )


def deploy_vault_balance_as_lending_connector(
    chain, lending_protocol, private_key, args_filename
):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR,
        CONTRACTS.WHITELIST_REGISTRY,
    )


def deploy_constant_slippage_connector(
    chain, lending_protocol, private_key, args_filename
):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.SLIPPAGE_CONNECTOR,
        CONTRACTS.VAULT_BALANCE_AS_LENDING_CONNECTOR,
    )


def deploy_oracle_connector(
    chain,
    lending_protocol,
    private_key,
    args_filename,
    contract=CONTRACTS.SLIPPAGE_CONNECTOR,
):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.ORACLE_CONNECTOR,
        contract,
    )


def deploy_lending_connector(
    chain,
    lending_protocol,
    private_key,
    args_filename,
    previous_contract=CONTRACTS.ORACLE_CONNECTOR,
):
    data = read_data(chain, lending_protocol, args_filename)

    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.LENDING_CONNECTOR,
        previous_contract,
    )


def deploy_ltv_beacon_proxy(chain, lending_protocol, private_key, args_filename):
    process_deployment(
        chain,
        lending_protocol,
        private_key,
        args_filename,
        CONTRACTS.LTV_BEACON_PROXY,
        CONTRACTS.LENDING_CONNECTOR,
    )


def deploy_ltv_implementation(args):
    deploy_erc20_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_borrow_vault_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_collateral_vault_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_low_level_rebalance_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_auction_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_administration_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_initialize_module(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_modules_provider(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_ltv(args.chain, args.lending_protocol, args.private_key, args.args_filename)


def deploy_connectors(args, contract):
    deploy_whitelist_registry(
        args.chain,
        args.lending_protocol,
        args.private_key,
        args.args_filename,
        contract,
    )
    deploy_vault_balance_as_lending_connector(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_constant_slippage_connector(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_oracle_connector(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )
    deploy_lending_connector(
        args.chain, args.lending_protocol, args.private_key, args.args_filename
    )


def read_data(chain, lending_protocol, args_filename):
    data = {}
    with open(get_args_file_path(chain, lending_protocol, args_filename), "r") as f:
        data.update(json.load(f))

    deployed_contracts_file_path = get_deployed_contracts_file_path(
        chain, lending_protocol, args_filename
    )
    if os.path.exists(deployed_contracts_file_path):
        with open(deployed_contracts_file_path, "r") as f:
            data.update(json.load(f))
    return data


def upgrade_ltv(args):
    if args.chain.find("local") != -1:
        prepare_upgrade_ltv(args)
        fake_ltv_roles(args)
        make_upgrade_ltv(args)
    else:
        prepare_upgrade_ltv(args)
        make_upgrade_ltv(args)


def prepare_upgrade_ltv(args):
    deploy_ltv_implementation(args)
    deploy_connectors(args, CONTRACTS.NONE)


def make_upgrade_ltv(args):
    data = read_data(args.chain, args.lending_protocol, args.args_filename)
    run_script(
        args.chain, CONTRACTS.UPGRADE, args.lending_protocol, args.private_key, data
    )
    print(f"SUCCESS LTV upgraded successfully")


def parse_address_from_result(output):
    return "0x" + output.strip()[26:]


def change_role_if_needed(data, dataKey, owner, role_signature, role_getter_signature):
    print(f"Getting {role_getter_signature} role of {dataKey} {data[dataKey]}")
    role_getter_result = subprocess.run(
        [f'cast call {data[dataKey]} "{role_getter_signature}"'],
        capture_output=True,
        shell=True,
        text=True,
    )
    output = handle_script_result(role_getter_result)
    role = parse_address_from_result(output)
    if role.lower() == TEST_USER_ADDRESS.lower():
        print(
            f"SUCCESS {role_getter_signature} role of {dataKey} {data[dataKey]} is already owned by {TEST_USER_ADDRESS}"
        )
        return
    print(
        f"Transferring {role_getter_signature} role of {dataKey} {data[dataKey]} to new {role_getter_signature}"
    )
    result = subprocess.run(
        ["cast", "rpc", "anvil_setBalance", owner, "0x152d02c7e14af6800000"],
        text=True,
        capture_output=True,
    )
    handle_script_result(result)
    result = subprocess.run(
        [
            "cast",
            "send",
            data[dataKey],
            "--from",
            owner,
            role_signature,
            TEST_USER_ADDRESS,
            "--unlocked",
        ],
        text=True,
        capture_output=True,
    )
    handle_script_result(result)
    print(
        f"SUCCESS Transferring {role_getter_signature} role of {dataKey} {data[dataKey]} to new {role_getter_signature}"
    )


def impersonate_owner_if_needed(data, dataKey):
    if not dataKey in data.keys():
        return

    print(f"Getting owner of {dataKey} {data[dataKey]}")
    result = subprocess.run(
        [f'cast call {data[dataKey]} "owner()"'],
        capture_output=True,
        shell=True,
        text=True,
    )
    output = handle_script_result(result)
    owner = parse_address_from_result(output)
    print(f"Owner of {dataKey} {data[dataKey]} is {owner}")

    print(f"Impersonating owner {owner}")
    result = subprocess.run(
        [f"cast rpc anvil_impersonateAccount {owner}"],
        text=True,
        capture_output=True,
        shell=True,
    )
    handle_script_result(result)
    print("SUCCESS Impersonating owner")

    change_role_if_needed(data, dataKey, owner, "transferOwnership(address)", "owner()")


def fake_ltv_roles(args):
    data = read_data(args.chain, args.lending_protocol, args.args_filename)
    impersonate_owner_if_needed(data, "BEACON")
    impersonate_owner_if_needed(data, "PROXY_ADMIN")
    impersonate_owner_if_needed(data, "LTV_BEACON_PROXY")
    impersonate_owner_if_needed(data, "WHITELIST_REGISTRY")
    change_role_if_needed(
        data,
        "LTV_BEACON_PROXY",
        TEST_USER_ADDRESS,
        "updateGuardian(address)",
        "guardian()",
    )
    change_role_if_needed(
        data,
        "LTV_BEACON_PROXY",
        TEST_USER_ADDRESS,
        "updateEmergencyDeleverager(address)",
        "emergencyDeleverager()",
    )
    change_role_if_needed(
        data,
        "LTV_BEACON_PROXY",
        TEST_USER_ADDRESS,
        "updateGovernor(address)",
        "governor()",
    )


def main():
    parser = argparse.ArgumentParser(description="Foundry Script")
    parser.add_argument(
        "--full-deploy", help="Full ltv protocol deployment", action="store_true"
    )
    parser.add_argument(
        "--chain",
        help="Chain to deploy to. Possible values: mainnet, local-fork-mainnet, local-fork-sepolia, sepolia",
        required=True,
    )
    parser.add_argument(
        "--lending-protocol",
        help="Lending protocol to deploy for. Possible values: aave, ghost, morpho",
        required=True,
    )
    parser.add_argument(
        "--args-filename",
        help="Name of the args file, stored in the deploy/(chain)/(lending_protocol) folder",
        required=True,
    )
    parser.add_argument("--etherscan-api-key", help="Etherscan API key")
    parser.add_argument(
        "--deploy-erc20-module", help="Deploy ERC20 module", action="store_true"
    )
    parser.add_argument(
        "--deploy-borrow-vault-module",
        help="Deploy Borrow vault module",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-collateral-vault-module",
        help="Deploy Collateral vault module",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-low-level-rebalance-module",
        help="Deploy Low level rebalance module",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-auction-module", help="Deploy Auction module", action="store_true"
    )
    parser.add_argument(
        "--deploy-administration-module",
        help="Deploy Administration module",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-initialize-module",
        help="Deploy Initialize module",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-modules-provider", help="Deploy Modules provider", action="store_true"
    )
    parser.add_argument("--deploy-ltv", help="Deploy LTV", action="store_true")
    parser.add_argument("--deploy-beacon", help="Deploy Beacon", action="store_true")
    parser.add_argument(
        "--deploy-whitelist-registry",
        help="Deploy Whitelist registry",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-vault-balance-as-lending-connector",
        help="Deploy Vault balance as lending connector",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-constant-slippage-connector",
        help="Deploy Constant slippage connector",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-oracle-connector", help="Deploy Oracle connector", action="store_true"
    )
    parser.add_argument(
        "--deploy-lending-connector",
        help="Deploy Lending connector",
        action="store_true",
    )
    parser.add_argument(
        "--deploy-ltv-beacon-proxy", help="Deploy LTV beacon proxy", action="store_true"
    )
    parser.add_argument(
        "--private-key",
        help="Private key to use for deployment (can also be set via PRIVATE_KEY env var)",
    )

    parser.add_argument(
        "--deploy-ltv-implementation",
        help="Deploy LTV implementation",
        action="store_true",
    )

    parser.add_argument(
        "--upgrade-ltv",
        help="Upgrade LTV",
        action="store_true",
    )

    parser.add_argument(
        "--deploy-connectors", help="Deploy connectors", action="store_true"
    )

    parser.add_argument(
        "--skip-anvil",
        help="Skip Anvil",
        action="store_true",
    )

    parser.add_argument(
        "--test-deployed-ltv-beacon-proxy-general-case",
        help="Test general deployed LTV beacon proxy",
        action="store_true",
    )

    parser.add_argument(
        "--test-deployed-ltv-beacon-proxy-lido",
        help="Test deployed LTV beacon proxy Lido",
        action="store_true",
    )

    args = parser.parse_args()

    if args.chain.find("local") != -1:
        args.private_key = TEST_USER_PRIVATE_KEY
        if args.chain == "local_fork_mainnet":
            rpc_url = " --fork-url " + os.environ["RPC_MAINNET"]
            block_number = " --fork-block-number 23699610"
        elif args.chain == "local_fork_sepolia":
            rpc_url = " --fork-url " + os.environ["RPC_SEPOLIA"]
            block_number = " --fork-block-number 9532361"
        else:
            rpc_url = ""
            block_number = ""

        if not args.skip_anvil:
            print("Please run the following command to start anvil:")
            print("anvil --port 8545" + rpc_url + block_number)
            print("Press Enter to continue...")
            input()

        subprocess.run(
            ["cast", "rpc", "anvil_setBlockTimestampInterval", "1"],
            text=True,
            capture_output=True,
        )

    elif not args.private_key:
        # Check for private key from environment variable if not provided as argument
        args.private_key = os.getenv("PRIVATE_KEY")
        if not args.private_key:
            print(
                "ERROR Private key must be provided either via --private-key argument or PRIVATE_KEY environment variable"
            )
            sys.exit(1)

    if args.deploy_erc20_module:
        deploy_erc20_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_borrow_vault_module:
        deploy_borrow_vault_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_collateral_vault_module:
        deploy_collateral_vault_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_low_level_rebalance_module:
        deploy_low_level_rebalance_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_auction_module:
        deploy_auction_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_administration_module:
        deploy_administration_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_initialize_module:
        deploy_initialize_module(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_modules_provider:
        deploy_modules_provider(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_ltv:
        deploy_ltv(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_beacon:
        deploy_beacon(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_whitelist_registry:
        deploy_whitelist_registry(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_vault_balance_as_lending_connector:
        deploy_vault_balance_as_lending_connector(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_constant_slippage_connector:
        deploy_constant_slippage_connector(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_oracle_connector:
        deploy_oracle_connector(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_lending_connector:
        deploy_lending_connector(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.deploy_ltv_beacon_proxy:
        deploy_ltv_beacon_proxy(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )
    if args.deploy_ltv_implementation:
        deploy_ltv_implementation(args)

    if args.deploy_connectors:
        deploy_connectors(args, CONTRACTS.NONE)

    if args.full_deploy:
        deploy_ltv_implementation(args)
        deploy_beacon(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )
        deploy_connectors(args, CONTRACTS.BEACON)
        deploy_ltv_beacon_proxy(
            args.chain, args.lending_protocol, args.private_key, args.args_filename
        )

    if args.upgrade_ltv:
        upgrade_ltv(args)

    if args.test_deployed_ltv_beacon_proxy_general_case:
        fake_ltv_roles(args)
        data = read_data(args.chain, args.lending_protocol, args.args_filename)
        run_script(
            args.chain,
            CONTRACTS.GENERAL_TEST,
            args.lending_protocol,
            args.private_key,
            data,
        )
        print("SUCCESS Test general deployed LTV beacon proxy completed")

    if args.test_deployed_ltv_beacon_proxy_lido:
        fake_ltv_roles(args)
        data = read_data(args.chain, args.lending_protocol, args.args_filename)
        run_script(
            args.chain,
            CONTRACTS.LIDO_TEST,
            args.lending_protocol,
            args.private_key,
            data,
        )
        print("SUCCESS Test deployed LTV beacon proxy Lido completed")


if __name__ == "__main__":
    main()
