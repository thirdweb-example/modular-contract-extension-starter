// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ModularExtension} from "@modular-contracts/ModularExtension.sol";
import {BeforeMintCallbackERC721} from "@modular-contracts/callback/BeforeMintCallbackERC721.sol";
import {Role} from "@modular-contracts/Role.sol";

library ExtensionStarterStorage {
    /// @custom:storage-location erc7201:token.minting.claimable.erc721
    bytes32 public constant STARTER_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("extension.starter")) - 1)) &
            ~bytes32(uint256(0xff));

    /// @notice The structure of the extension's storage.
    struct Data {
        uint256 mintPrice;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = STARTER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

/// @notice This starter template is meant to be used as a starting point for
///        developing your own extension.
contract ExtensionStarter is ModularExtension, BeforeMintCallbackERC721 {
    /// @notice Returns the Extension Configuration.
    /// @dev The Extension Configuration includes the followings:
    ///      - callbackFunctions: The array of callback functions that the extension implements.
    ///      - fallbackFunctions: The array of fallback functions that the extension implements.
    ///      - requiredInterfaces: The array of required interfaces that the extension requires of the core.
    ///      - supportedInterfaces: The array of interfaces that the extension supports.
    ///      - registerInstallationCallback: Whether to register the onInstall and onUninstall callbacks.
    function getExtensionConfig()
        external
        pure
        override
        returns (ExtensionConfig memory config)
    {
        // The array of callback functions that the extension implements.
        config.callbackFunctions = new CallbackFunction[](1);
        config.callbackFunctions[0] = CallbackFunction(
            this.beforeMintERC721.selector
        );

        // The array of fallback functions that the extension implements.
        config.fallbackFunctions = new FallbackFunction[](2);
        config.fallbackFunctions[0] = FallbackFunction(
            this.getMintPrice.selector,
            0
        );
        config.fallbackFunctions[1] = FallbackFunction({
            selector: this.setMintPrice.selector,
            permissionBits: Role._MANAGER_ROLE
        });

        // The array of required interfaces that the extension requires of the core.
        config.requiredInterfaces = new bytes4[](1);
        config.requiredInterfaces[0] = 0x36372b07; // ERC20

        // The array of interfaces that the extension supports.
        config.supportedInterfaces = new bytes4[](1);
        config.supportedInterfaces[0] = 0x000000;

        // Flag to check whether to register the onInstall and onUninstall callbacks.
        config.registerInstallationCallback = true;
    }

    /// @notice Called by a Core into an Extension during the installation of the Extension.
    function onInstall(bytes calldata data) external {
        uint256 _mintPrice = abi.decode(data, (uint256));
        _starterStorage().mintPrice = _mintPrice;
    }

    /// @notice Called by a Core into an Extension during the uninstallation of the Extension.
    function onUninstall(bytes calldata data) external {}

    /// @notice Triggers an action before the main function.
    /// @dev This function is called by the core before the _mint function
    ///      through a delegatecall to the extension.
    ///
    ///      For a list of all possible callbacks from the current core
    ///      contract offerings, reference the README.
    function beforeMintERC721(
        address _to,
        uint256 _startTokenId,
        uint256 _quantity,
        bytes memory _data
    ) external payable virtual override returns (bytes memory) {
        require(
            msg.value == _starterStorage().mintPrice * _quantity,
            "Insufficient ETH sent"
        );
    }

    /// @notice Fetches the mint price.
    /// @dev This function is called through the core's fallback function
    ///      via a delegatecall to the extension.
    function getMintPrice() external view returns (uint256) {
        return _starterStorage().mintPrice;
    }

    /// @notice Sets the mint price.
    /// @dev This function is called through the core's fallback function
    ///      via a delegatecall to the extension.
    ///      This function can only be called with the correct permissions.
    function setMintPrice(uint256 _mintPrice) external {
        _starterStorage().mintPrice = _mintPrice;
    }

    /// @notice utility function to help get the storage data for the extension
    function _starterStorage()
        internal
        pure
        returns (ExtensionStarterStorage.Data storage)
    {
        return ExtensionStarterStorage.data();
    }
}
