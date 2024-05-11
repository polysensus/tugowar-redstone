// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";
import {console2 as console } from "forge-std/console2.sol";

contract ERC6551Account is
    IERC165,
    IERC1271,
    IERC6551Account,
    IERC6551Executable,
    ERC1155Holder
{
    uint256 public state;

    receive() external payable {}

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable virtual returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");

        ++state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view virtual returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view virtual returns (bytes4 magicValue) {
        // In order to support ERC1155 and ERC721, don't rely on being able to
        // call ownerOf.
        address signer = _recoverSigner(hash, signature);
        if (signer == address(0)) return bytes4(0);

        // note that we do not try to reuse isValidSigner as that considers the
        // chainId. With respect to signatures, the chainId is neutral.
        // Otherwise signed payloads could not cross chains or layers.

        (, address tokenContract, uint256 tokenId) = token();

        if (
            IERC165(tokenContract).supportsInterface(type(IERC1155).interfaceId)
        ) {

            // XXX: WARNING: It is really not clear yet what the safe patterns
            // are for binding to ERC 1155 tokens. Its fine for TBA's to *own*
            // ERC1155's or any other asset. its just binding the TBA to an ERC
            // 1155 that is "permitted" by the standard but not on "the common
            // path".
            // If the signer has a balnce of 1 for the bound token, the it is
            // a valid owner.
            uint256 balance = IERC1155(tokenContract).balanceOf(
                signer,
                tokenId
            );
            // ** NOTICE *** this still permits the same id to be minted to
            // multiple owners. That is at the discretion of the token
            // implementation. In which case ** ANY ** owner will be considered
            // a valid signer. Depending on use case this is either a very useful
            // feature or a very bad bug.
            if (balance != 1) return bytes4(0);
            // The recovered signer has a balance of 1 for the token id bound to
            // this account.
            return IERC1271.isValidSignature.selector;
        }

        if (signer != IERC721(tokenContract).ownerOf(tokenId)) return bytes4(0);

        return IERC1271.isValidSignature.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override (ERC1155Holder, IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token() public view virtual returns (uint256, address, uint256) {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function _isValidSigner(
        address signer
    ) internal view virtual returns (bool) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();

        console.log(tokenId);
        console.log("checking block");

        if (chainId != block.chainid) return false;

        if (
            IERC165(tokenContract).supportsInterface(type(IERC1155).interfaceId)
        ) {
            uint256 balance = IERC1155(tokenContract).balanceOf(
                signer,
                tokenId
            );
            // ** NOTICE *** this still permits the same id to be minted to
            // multiple owners. In which case ** ANY ** owner will be considered
            // a valid signer. Depending on use case this is either a very useful
            // feature or a very bad bug.
            return balance == 1;
        }
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        console.log(signer, tokenOwner);

        return signer == tokenOwner;
    }

    /**
     * @dev recovers the signer address from the signature */
    function _recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, ECDSA.RecoverError err, ) = ECDSA.tryRecover(
            hash,
            signature
        );
        if (err != ECDSA.RecoverError.NoError) return address(0);
        return recovered;
    }
}
