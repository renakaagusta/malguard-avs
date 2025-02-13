pragma solidity ^0.8.26;
// SPDX-License-Identifier: MIT
interface ISafeGuard {
    function allowFunction(address target, bytes4 functionSelector) external;
}