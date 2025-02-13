// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHelloWorldServiceManager {
    event NewTaskCreated(uint32 indexed taskIndex, Task task);

    event TaskResponded(uint32 indexed taskIndex, Task task, address operator);
    event Transaction(uint32 indexed taskIndex, address indexed from, address indexed to, uint256 value, bytes data, bytes message, bool status);
    struct Task {
        uint32 taskCreatedBlock;
        address from;
        address to;
        bytes data;
        uint256 value;
    }

    function latestTaskNum() external view returns (uint32);

    function allTaskHashes(
        uint32 taskIndex
    ) external view returns (bytes32);

    function allTaskResponses(
        address operator,
        uint32 taskIndex
    ) external view returns (bytes memory);

    function createNewTask(
        address from,
        address to,
        bytes memory data,
        uint256 value
    ) external returns (Task memory);

    function respondToTask(
        Task calldata task,
        uint32 referenceTaskIndex,
        bytes memory signature,
        bool isSafe,
        bytes memory causeHash
    ) external;
}
