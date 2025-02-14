// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "safe-smart-account/contracts/Safe.sol";

interface IFaucet {
    // Events
    event AddToken(address token);
    event UpdateFaucetAmount(uint256 amount);
    event UpdateFaucetCooldown(uint256 cooldown);
    event RequestToken(address requester, address receiver, address token);
    event DepositToken(address depositor, address token, uint256 amount);

    // View Functions
    function owner() external view returns (address);
    function availableTokens(uint256) external view returns (address);
    function faucetAmount() external view returns (uint256);
    function faucetCooldown() external view returns (uint256);
    function lastRequestTime(address) external view returns (uint256);
    function getAvailableTokensLength() external view returns (uint256);
    function getLastRequestTime() external view returns (uint256);
    function getAvailabilityTime() external view returns (uint256);
    function getCooldown() external view returns (uint256);
    function getCurrentTimestamp() external view returns (uint256);

    // State-Changing Functions
    function addToken(address _token) external;
    function updateFaucetAmount(uint256 _faucetAmount) external;
    function updateFaucetCooldown(uint256 _faucetCooldown) external;
    function requestToken(address _receiver, address _token) external;
    function depositToken(address _token, uint256 _amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FaucetApprove is Script {
    // Replace these with your deployed addresses
    address SAFE_ADDRESS = vm.envAddress("SAFE_ADDRESS"); // Your deployed Safe address
    address FAUCET_ADDRESS = vm.envAddress("FAUCET_ADDRESS"); // Your deployed Faucet address
    address TOKEN_ADDRESS = vm.envAddress("IDRT_ADDRESS"); // Your ERC20 token address

        // Array of owner private keys (from .env file)
    function getOwnerPrivateKeys() internal view returns (uint256[] memory) {
        uint256[] memory privateKeys = new uint256[](2);
        
        for(uint i = 1; i <= 2; i++) {
            privateKeys[i-1] = vm.envUint(string.concat("PRIVATE_KEY_", vm.toString(i)));
        }
        
        return privateKeys;
    }

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_1"));

        uint256[] memory ownerPrivateKeys = getOwnerPrivateKeys();
        address[] memory owners = new address[](ownerPrivateKeys.length);
        
        for(uint i = 0; i < ownerPrivateKeys.length; i++) {
            owners[i] = vm.addr(ownerPrivateKeys[i]);
        }

        Safe safe = Safe(payable(SAFE_ADDRESS));
        IFaucet faucet = IFaucet(FAUCET_ADDRESS);
        IERC20 token = IERC20(TOKEN_ADDRESS);

        // Check threshold
        uint256 threshold = safe.getThreshold();
        require(ownerPrivateKeys.length >= threshold, "Not enough signers provided");

        // Add these debug logs
        console.log("Safe owners:");
        address[] memory safeOwners = safe.getOwners();
        for(uint i = 0; i < safeOwners.length; i++) {
            console.log(safeOwners[i]);
        }
        
        console.log("Signing owners:");
        for(uint i = 0; i < owners.length; i++) {
            console.log(owners[i]);
        }
        // Before approve transaction
        console.log("Current allowance:", token.allowance(SAFE_ADDRESS, FAUCET_ADDRESS));
        
        // Example: Deposit tokens
        uint256 depositAmount = 10 * 10**18;
        
        bytes memory approveData = abi.encodeWithSelector(
            IERC20.approve.selector,
            FAUCET_ADDRESS,
            depositAmount
        );

        executeTransactionWithMultiSig(
            safe,
            TOKEN_ADDRESS,
            0,
            approveData,
            ownerPrivateKeys,
            threshold
        );

        vm.stopBroadcast();
    }

    function executeTransactionWithMultiSig(
        Safe safe,
        address to,
        uint256 value,
        bytes memory data,
        uint256[] memory privateKeys,
        uint256 threshold
    ) internal {
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address payable refundReceiver = payable(address(0));

        // Generate transaction hash
        bytes32 txHash = safe.getTransactionHash(
            to,
            value,
            data,
            Enum.Operation.Call,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            safe.nonce()
        );

        // Collect signatures from owners
        bytes memory signatures = "";
        
        // Sort owners by address (required by Safe)
        (uint256[] memory sortedKeys, address[] memory sortedOwners) = sortOwnersByAddress(privateKeys);

        // Collect required number of signatures
        for(uint i = 0; i < threshold; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(sortedKeys[i], txHash);
            signatures = abi.encodePacked(signatures, abi.encodePacked(r, s, v));
        }

        // Execute transaction
        bool success = safe.execTransaction(
            to,
            value,
            data,
            Enum.Operation.Call,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            signatures
        );

        require(success, "Transaction execution failed");
    }

    // Helper function to sort owners by address (required by Safe)
    function sortOwnersByAddress(uint256[] memory privateKeys) internal view returns (uint256[] memory, address[] memory) {
        uint256 len = privateKeys.length;
        uint256[] memory sortedKeys = new uint256[](len);
        address[] memory sortedOwners = new address[](len);
        
        // Initialize arrays
        for(uint i = 0; i < len; i++) {
            sortedKeys[i] = privateKeys[i];
            sortedOwners[i] = vm.addr(privateKeys[i]);
        }
        
        // Bubble sort (you might want to use a more efficient sorting algorithm for production)
        for(uint i = 0; i < len; i++) {
            for(uint j = 0; j < len - 1 - i; j++) {
                if(sortedOwners[j] > sortedOwners[j + 1]) {
                    // Swap addresses
                    address tempAddr = sortedOwners[j];
                    sortedOwners[j] = sortedOwners[j + 1];
                    sortedOwners[j + 1] = tempAddr;
                    
                    // Swap keys
                    uint256 tempKey = sortedKeys[j];
                    sortedKeys[j] = sortedKeys[j + 1];
                    sortedKeys[j + 1] = tempKey;
                }
            }
        }
        
        return (sortedKeys, sortedOwners);
    }
}