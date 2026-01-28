// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {memmove} from "./mem.sol";

/**
 * @dev Returns a new string by repeating the slice `n` times.
 */
function repeat(
    uint256 ptr,
    uint256 len,
    uint256 n
) view returns (string memory) {
    if (n == 0 || len == 0) return "";
    uint256 totalLen = len * n;
    string memory result = new string(totalLen);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }

    for (uint256 i = 0; i < n; i++) {
        memmove(destPtr + (i * len), ptr, len);
    }
    return result;
}

/**
 * @dev Pads the slice on the left with `char` to reach `totalLen`.
 */
function padLeft(
    uint256 ptr,
    uint256 len,
    uint256 totalLen,
    bytes1 char
) view returns (string memory) {
    if (totalLen <= len) return _toString(ptr, len);
    string memory result = new string(totalLen);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }

    uint256 padLen = totalLen - len;
    for (uint256 i = 0; i < padLen; i++) {
        assembly {
            mstore8(add(destPtr, i), byte(0, char))
        }
    }
    memmove(destPtr + padLen, ptr, len);
    return result;
}

/**
 * @dev Pads the slice on the right with `char` to reach `totalLen`.
 */
function padRight(
    uint256 ptr,
    uint256 len,
    uint256 totalLen,
    bytes1 char
) view returns (string memory) {
    if (totalLen <= len) return _toString(ptr, len);
    string memory result = new string(totalLen);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }

    memmove(destPtr, ptr, len);
    for (uint256 i = len; i < totalLen; i++) {
        assembly {
            mstore8(add(destPtr, i), byte(0, char))
        }
    }
    return result;
}

/**
 * @dev Converts a uint256 to its hex string representation (0x prefixed).
 */
function toHexString(uint256 value) pure returns (string memory) {
    if (value == 0) return "0x00";
    uint256 temp = value;
    uint256 length = 0;
    while (temp > 0) {
        length++;
        temp >>= 8;
    }
    return toHexString(value, length);
}

/**
 * @dev Converts a uint256 to its hex string representation with specific byte length.
 */
function toHexString(
    uint256 value,
    uint256 length
) pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    bytes memory alphabet = "0123456789abcdef";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
        buffer[i] = alphabet[value & 0xf];
        value >>= 4;
    }
    return string(buffer);
}

/**
 * @dev Internal helper to copy slice to new string
 */
function _toString(
    uint256 ptr,
    uint256 len
) view returns (string memory result) {
    result = new string(len);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }
    memmove(destPtr, ptr, len);
}
