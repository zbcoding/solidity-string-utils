// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Parse__InvalidUint();
error Parse__InvalidAddress();

/**
 * @dev Converts a numeric ASCII string slice to a uint256.
 * Reverts on invalid characters.
 */
function toUint(uint256 ptr, uint256 len) pure returns (uint256 result) {
    if (len == 0) revert Parse__InvalidUint();
    for (uint256 i = 0; i < len; i++) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(ptr, i)))
        }
        if (b < 0x30 || b > 0x39) revert Parse__InvalidUint();
        unchecked {
            uint256 next = result * 10 + (b - 0x30);
            if (next < result) revert Parse__InvalidUint(); // Overflow
            result = next;
        }
    }
}

/**
 * @dev Converts a hex string slice to an address.
 * Supports optional "0x" prefix.
 */
function toAddress(uint256 ptr, uint256 len) pure returns (address addr) {
    uint256 start = 0;
    if (len >= 2) {
        uint8 b0;
        uint8 b1;
        assembly {
            b0 := byte(0, mload(ptr))
            b1 := byte(0, mload(add(ptr, 1)))
        }
        if (b0 == 0x30 && (b1 == 0x78 || b1 == 0x58)) {
            start = 2;
        }
    }

    if (len - start != 40) revert Parse__InvalidAddress();

    uint160 result = 0;
    for (uint256 i = start; i < len; i++) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(ptr, i)))
        }
        uint8 val;
        if (b >= 0x30 && b <= 0x39) {
            val = b - 0x30;
        } else if (b >= 0x61 && b <= 0x66) {
            val = b - 0x61 + 10;
        } else if (b >= 0x41 && b <= 0x46) {
            val = b - 0x41 + 10;
        } else {
            revert Parse__InvalidAddress();
        }
        unchecked {
            result = (result << 4) | val;
        }
    }
    return address(result);
}
