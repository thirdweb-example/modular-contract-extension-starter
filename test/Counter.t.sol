// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ExtensionStarter} from "../src/ExtensionStarter.sol";
import {ModularCore} from "@modular-contracts/ModularCore.sol";

contract Core is ModularCore {
    function getSupportedCallbackFunctions()
        public
        pure
        override
        returns (SupportedCallbackFunction[] memory supportedCallbackFunctions)
    {
        supportedCallbackFunctions = new SupportedCallbackFunction[](1);
        supportedCallbackFunctions[0] = SupportedCallbackFunction.Mint;
    }
}

contract CounterTest is Test {
    ExtensionStarter public extension;
    ERC20Core public erc20;

    address owner = address(0x123);

    address minter = address(0x456);
    uint256 amount = 100 ether;

    uint256 pricePerUnit = 1 ether;

    function setUp() public {
        // Deploy contracts
        vm.prank(owner);
        erc20 = new ERC20Core();
        extension = new ExtenionStarter();

        // Install extension
        vm.prank(owner);
        erc20.installExtension(address(extension), "");
    }

    function test_mint() public {
        // Mint tokens
        assertEq(erc20.balanceOf(minter), 0);
        assertEq(minter.balance, 100 ether);
        assertEq(owner.balance, 0);

        vm.prank(minter);
        erc20.mint{value: 100 ether}(minter, amount);

        assertEq(erc20.balanceOf(minter), amount);
        assertEq(minter.balance, 0);
        assertEq(owner.balance, 100 ether);
    }

    function test_revert_mint_insufficientPriceSent() public {
        vm.prank(minter);
        vm.expectRevert();
        erc20.mint{value: 100 ether - 1}(minter, amount);
    }
}
