// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {LTV} from '../src/LTV.sol';
import {HodlLendingConnector} from '../src/ghost/connectors/HodlLendingConnector.sol';
import {SpookyOracleConnector} from '../src/ghost/connectors/SpookyOracleConnector.sol';
import {IHodlMyBeerLending} from '../src/ghost/hodlmybeer/IHodlMyBeerLending.sol';
import {ISpookyOracle} from '../src/ghost/spooky/ISpookyOracle.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import 'forge-std/StdAssertions.sol';
import 'forge-std/Script.sol';


contract GhostUpgradeTest is Script, StdAssertions {
    function run() public {
        LTV ltv = LTV(0xE2A7f267124AC3E4131f27b9159c78C521A44F3c);
        uint256 oldPreview = ltv.previewDeposit(10**18);

        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(payable(address(ltv)));
        address admin = address(bytes20(uint160(uint256(vm.load(address(ltv), 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)))));
        LTV ltvImpl = new LTV();
        vm.startPrank(admin);

        address _collateralToken = 0x8f7b2044F9aA6fbf495c1cC3bDE120dF9032aE43;
        address _borrowToken = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        address _lendingProtocol = 0x1Dcd756db287354c4607D5d57621cdfb4456E2d4;
        address _oracle = 0x6074D1d4022521147DB1faD7BACC486B35A64dF3;
        
        HodlLendingConnector lendingConnector = new HodlLendingConnector(
            IERC20(_collateralToken),
            IERC20(_borrowToken),
            IHodlMyBeerLending(_lendingProtocol)
        );

        SpookyOracleConnector oracleConnector = new SpookyOracleConnector(
            IERC20(_collateralToken),
            IERC20(_borrowToken),
            ISpookyOracle(_oracle)
        );

        proxy.upgradeToAndCall(address(ltvImpl), '');
        vm.stopPrank();
        vm.startPrank(ltv.owner());
        ltv.setMissingSlots(lendingConnector, oracleConnector);

        assertEq(ltv.previewDeposit(10**18), oldPreview);
        require(ltv.maxDeposit(address(this)) > 0);
        ltv.previewLowLevelShares(0);
    }
}