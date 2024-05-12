// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev the ERC-165 identifier for this interface is `TODO: xxx`
interface IERC6551LastExecutor {
    /**
     * @dev Returns the msg.sender that most recently *successfuly* executed a
     * call on the account Can't do ownerOf generically for ERC115. But we can
     * track the last message sender to execute using the account.
     * This may or may not be an EOA,  but MUST be the token holder and the
     * signer
     * @param id   the tokenId
     * @return The msg.sender that last executed or address(0) if id is unkown
     */
    function lastExecutor(uint256 id) external view returns (address);
}
