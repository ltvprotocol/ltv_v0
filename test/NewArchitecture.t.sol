// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import './utils/LTVWithModules.sol';
import 'src/elements/BorrowVaultModule.sol';
import 'src/elements/CollateralVaultModule.sol';
import 'src/elements/AuctionModule.sol';
import 'src/states/ModulesProvider.sol';
import {GeneratedTests} from './Generated.t.sol';
import {DummyLTVTest} from './DummyLTV.t.sol';

contract NewArchitectureGeneratedTest is GeneratedTests {
    function needToReplaceImplementation() internal override pure returns (bool) {
        return true;
    }
}

contract NewArchitectureTest is DummyLTVTest {
    function needToReplaceImplementation() internal override pure returns (bool) {
        return true;
    }
}
