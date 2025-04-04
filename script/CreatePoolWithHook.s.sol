// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";

import {BaseSepoliaConstants} from "../script/base/BaseSepoliaConstants.sol";

contract CreatePoolWithHook is Script, BaseSepoliaConstants {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    // MODIFIED: Changed fee tier to 500 (0.05%) instead of 3000 (0.3%)
    // This should create a new pool instead of trying to use an existing one
    uint24 lpFee = 500;     // 0.05% fee
    int24 tickSpacing = 60; // Keep the same tick spacing
    uint160 startingPrice = 79228162514264337593543950336; // 1.0 price in sqrtPriceX96
    
    // Token addresses on Base Sepolia
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    // Your deployed hook address
    address hookAddress;
    
    Currency currency0;
    Currency currency1;

    function setUp() public {
        // Load your deployed hook address from environment or set it directly
        hookAddress = vm.envAddress("HOOK_ADDRESS");
        
        // Set up currencies - ensure they're sorted
        if (uint160(USDC) < uint160(WETH)) {
            currency0 = Currency.wrap(USDC);
            currency1 = Currency.wrap(WETH);
        } else {
            currency0 = Currency.wrap(WETH);
            currency1 = Currency.wrap(USDC);
        }
    }

    function run() public {
        // Get private key from environment variable
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);
        
        // Create pool key with your hook
        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hookAddress)
        });

        // Try to initialize the pool and handle errors
        try POOLMANAGER.initialize(pool, startingPrice) {
            console.log("Pool created successfully with DynamicFeeHook on Base Sepolia");
            console.log("Fee Tier: %d", lpFee);
            console.log("Currency0:", Currency.unwrap(currency0));
            console.log("Currency1:", Currency.unwrap(currency1));
            console.log("Pool ID:", string(abi.encodePacked(pool.toId())));
        } catch (bytes memory err) {
            console.log("Failed to create pool. Error:");
            console.logBytes(err);
        }
        
        vm.stopBroadcast();
    }
}