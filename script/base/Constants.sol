// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {BaseSepoliaConstants} from "../../src/BaseSepoliaConstants.sol";
import {DynamicFeeHook} from "../../src/DynamicFeeHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

/// @notice Deploys the DynamicFeeHook.sol contract to Base Sepolia
contract DeployToBaseSepoliaScript is Script, BaseSepoliaConstants {
    function setUp() public {
        // Load environment variables
        // Private key should be loaded from .env file
    }

    function run() public {
        // Get private key from environment variable
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);
        
        // Hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_INITIALIZE_FLAG | 
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(POOLMANAGER);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(DynamicFeeHook).creationCode, constructorArgs);

        // Deploy the hook using CREATE2
        DynamicFeeHook dynamicFeeHook = new DynamicFeeHook{salt: salt}(IPoolManager(POOLMANAGER));
        require(address(dynamicFeeHook) == hookAddress, "DeployToBaseSepoliaScript: hook address mismatch");

        console.log("DynamicFeeHook deployed to Base Sepolia at:", address(dynamicFeeHook));
        
        vm.stopBroadcast();
    }
}