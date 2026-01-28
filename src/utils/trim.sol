// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Returns true if the byte is an ASCII whitespace character.
 */
function isWhitespace(uint8 b) pure returns (bool) {
    // Space (0x20), Tab (0x09), Newline (0x0A), Vertical Tab (0x0B), Form Feed (0x0C), Carriage Return (0x0D)
    return (b == 0x20 || (b >= 0x09 && b <= 0x0D));
}

/**
 * @dev Returns the pointer and length of a slice with leading and trailing whitespace removed.
 */
function trim(
    uint256 ptr,
    uint256 len
) pure returns (uint256 outPtr, uint256 outLen) {
    (outPtr, outLen) = trimStart(ptr, len);
    (outPtr, outLen) = trimEnd(outPtr, outLen);
}

/**
 * @dev Returns the pointer and length of a slice with leading whitespace removed.
 */
function trimStart(
    uint256 ptr,
    uint256 len
) pure returns (uint256 outPtr, uint256 outLen) {
    uint256 i = 0;
    while (i < len) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(ptr, i)))
        }
        if (!isWhitespace(b)) break;
        unchecked {
            i++;
        }
    }
    unchecked {
        return (ptr + i, len - i);
    }
}

/**
 * @dev Returns the pointer and length of a slice with trailing whitespace removed.
 */
function trimEnd(
    uint256 ptr,
    uint256 len
) pure returns (uint256 outPtr, uint256 outLen) {
    uint256 i = len;
    while (i > 0) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(ptr, sub(i, 1))))
        }
        if (!isWhitespace(b)) break;
        unchecked {
            i--;
        }
    }
    return (ptr, i);
}
