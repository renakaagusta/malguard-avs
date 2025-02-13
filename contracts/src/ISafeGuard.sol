// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface ISafeGuard {
    // Events
    event FunctionAllowed(address indexed target, bytes4 indexed functionSelector);
    event FunctionRemoved(address indexed target, bytes4 indexed functionSelector);

    // View Functions
    function owner() external view returns (address);
    function serviceManager() external view returns (address);
    function allowedFunctions(address target, bytes4 functionSelector) external view returns (bool);
    
    // State-changing Functions
    function allowFunction(address target, bytes4 functionSelector) external;
    function removeFunction(address target, bytes4 functionSelector) external;
    
    // Guard Functions
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external view;
    
    function checkAfterExecution(bytes32 txHash, bool success) external pure;
    
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        address module
    ) external returns (bytes32 moduleTxHash);
    
    function checkAfterModuleExecution(bytes32 txHash, bool success) external;
    
    // ERC165 Support
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}