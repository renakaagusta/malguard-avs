pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

interface IServiceManager {
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


contract CreateTask is Script {
    function run() public {
        // Get environment variables
        address serviceManager = vm.envAddress("SERVICE_MANAGER_ADDRESS");
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address targetContract = vm.envAddress("FAUCET_ADDRESS");

        // Example function selector (replace with your desired function)
        bytes4 functionSelector = bytes4(keccak256("someFunction()"));
        
        // Encode the function call data
        bytes memory data = abi.encode(targetContract, functionSelector);

        vm.startBroadcast(deployerKey);
        
        // Create new task
        // from: msg.sender (deployer)
        // to: target contract
        // data: encoded function data
        // value: 0 (no ETH sent)
        IServiceManager(serviceManager).createNewTask(
            vm.addr(deployerKey),  // from
            targetContract,        // to
            data,                 // encoded data
            0                     // value
        );
        
        vm.stopBroadcast();
    }
}
