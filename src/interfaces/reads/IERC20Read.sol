// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { StateRepresentationStruct } from "../../structs/StateRepresentationStruct.sol";

interface IERC20Read {

    function totalSupply(uint256 baseTotalSupply) external view returns (uint256);

}