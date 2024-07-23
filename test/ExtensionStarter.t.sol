// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/forge-std/src/console.sol";

import {Test, console} from "forge-std/Test.sol";

import {Role} from "@modular-contracts/Role.sol";
import {ERC721Core} from "@modular-contracts/core/token/ERC721Core.sol";
import {ExtensionStarterStorage, ExtensionStarter} from "../src/ExtensionStarter.sol";

interface IERC20 {
    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract ClaimableERC721Test is Test {
    ERC721Core public core;
    ExtensionStarter public extension;

    address public owner = address(1);
    address public minter = address(2);

    function setUp() public {
        vm.startPrank(owner);
        permissionedActor = vm.addr(permissionedActorPrivateKey);
        unpermissionedActor = vm.addr(unpermissionedActorPrivateKey);

        address[] memory extensions;
        bytes[] memory extensionData;

        core = new ERC721Core(
            "test",
            "TEST",
            "",
            owner,
            extensions,
            extensionData
        );
        extension = new ClaimableERC721();

        // install extension
        bytes memory encodedInstallParams = abi.encode(1 ether);
        core.installExtension(address(extension), encodedInstallParams);

        // Give permissioned actor minter role
        core.grantRoles(permissionedActor, Role._MANAGER_ROLE);

        vm.stopPrank();
    }

    function test_mint() public {
        uint256 amount = 100;
        vm.hoax(minter, 100 ether);
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
