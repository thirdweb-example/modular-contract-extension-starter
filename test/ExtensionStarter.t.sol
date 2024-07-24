// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/forge-std/src/console.sol";

import {Test, console} from "forge-std/Test.sol";

import {Role} from "@modular-contracts/Role.sol";
import {ERC721Core} from "@modular-contracts/core/token/ERC721Core.sol";
import {ExtensionStarterStorage, ExtensionStarter} from "../src/ExtensionStarter.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function mint(address to, uint256 tokenId) external;
}

contract ExtensionStarterTest is Test {
    event MintPriceSet(uint256 mintPrice);

    ERC721Core public core;
    ExtensionStarter public extension;

    address public owner = address(1);
    address public minter = address(2);

    uint256 amount = 10;

    function setUp() public {
        vm.startPrank(owner);
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
        extension = new ExtensionStarter();

        // install extension
        bytes memory encodedInstallParams = abi.encode(1 ether);
        core.installExtension(address(extension), encodedInstallParams);

        // give owner manager role
        core.grantRoles(owner, Role._MANAGER_ROLE);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        Tests: Minting
    //////////////////////////////////////////////////////////////*/

    function test_mint() public {
        hoax(minter, 10 ether);
        core.mint{value: 10 ether}(minter, amount, "");

        assertEq(core.balanceOf(minter), amount);
        assertEq(minter.balance, 0);
        assertEq(address(core).balance, 10 ether);
    }

    function test_revert_mint_insufficientPriceSent() public {
        hoax(minter, 10 ether);
        vm.expectRevert("Insufficient ETH sent");
        core.mint{value: 10 ether - 1}(minter, amount, "");
    }

    /*//////////////////////////////////////////////////////////////
                        Tests: get / set Mint Price
    //////////////////////////////////////////////////////////////*/

    function test_getMintPrice() public {
        assertEq(ExtensionStarter(address(core)).getMintPrice(), 1 ether);
    }

    function test_setMintPrice() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit MintPriceSet(2 ether);
        ExtensionStarter(address(core)).setMintPrice(2 ether);

        assertEq(ExtensionStarter(address(core)).getMintPrice(), 2 ether);
    }

    function test_revert_setMintPriceInsufficientPermission() public {
        vm.expectRevert(0x82b42900);
        ExtensionStarter(address(core)).setMintPrice(2 ether);
    }
}
