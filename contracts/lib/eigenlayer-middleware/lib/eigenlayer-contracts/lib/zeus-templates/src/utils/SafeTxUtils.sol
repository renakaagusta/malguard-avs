// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {ISafe, EncGnosisSafe} from "../utils/EncGnosisSafe.sol";

/// @notice SafeTx data struct
/// @dev based on <https://docs.safe.global/sdk/api-kit/guides/propose-and-confirm-transactions#propose-a-transaction-to-the-service>
struct SafeTx {
    address to;
    uint256 value;
    bytes data;
    EncGnosisSafe.Operation op;
}

library SafeTxUtils {
    function encodeForExecutor(SafeTx memory t, address timelock) public pure returns (bytes memory) {
        // TODO: validate the correctness of this sig
        bytes1 v = bytes1(uint8(1));
        bytes32 r = bytes32(uint256(uint160(timelock)));
        bytes32 s;
        bytes memory sig = abi.encodePacked(r, s, v);

        bytes memory executorCalldata = abi.encodeWithSelector(
            ISafe.execTransaction.selector,
            t.to,
            t.value,
            t.data,
            t.op,
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(uint160(0)), // gasToken
            payable(address(uint160(0))), // refundReceiver
            sig
        );

        return executorCalldata;
    }
}
