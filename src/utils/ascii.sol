// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Returns a new string with all ASCII lowercase letters converted to uppercase.
 * Non-ASCII characters are left unchanged.
 */
function toUpperCaseEnglish(
    uint256 sourcePtr,
    uint256 length
) view returns (string memory) {
    string memory result = new string(length);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }

    for (uint256 i = 0; i < length; i++) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(sourcePtr, i)))
        }
        // 'a' = 0x61, 'z' = 0x7A
        if (b >= 0x61 && b <= 0x7A) {
            b -= 0x20; // 'a' -> 'A'
        }
        assembly {
            mstore8(add(destPtr, i), b)
        }
    }
    return result;
}

/**
 * @dev Returns a new string with all ASCII uppercase letters converted to lowercase.
 * Non-ASCII characters are left unchanged.
 */
function toLowerCaseEnglish(
    uint256 sourcePtr,
    uint256 length
) view returns (string memory) {
    string memory result = new string(length);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }

    for (uint256 i = 0; i < length; i++) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(sourcePtr, i)))
        }
        // 'A' = 0x41, 'Z' = 0x5A
        if (b >= 0x41 && b <= 0x5A) {
            b += 0x20; // 'A' -> 'a'
        }
        assembly {
            mstore8(add(destPtr, i), b)
        }
    }
    return result;
}

/**
 * @dev Returns true if two string slices are equal regardless of case.
 * Only handles ASCII letters (a-z, A-Z).
 */
function equalsIgnoreCaseEnglish(
    uint256 ptr1,
    uint256 len1,
    uint256 ptr2,
    uint256 len2
) pure returns (bool) {
    if (len1 != len2) return false;
    for (uint256 i = 0; i < len1; i++) {
        uint8 b1;
        uint8 b2;
        assembly {
            b1 := byte(0, mload(add(ptr1, i)))
            b2 := byte(0, mload(add(ptr2, i)))
        }
        if (b1 == b2) continue;
        // Check if they differ only by case
        if (b1 ^ b2 == 0x20) {
            uint8 lower = b1 | 0x20;
            if (lower >= 0x61 && lower <= 0x7A) continue;
        }
        return false;
    }
    return true;
}

/**
 * @dev Returns a new string with the first ASCII character capitalized.
 */
function capitalizeEnglish(
    uint256 sourcePtr,
    uint256 length
) view returns (string memory) {
    if (length == 0) return "";
    string memory result = new string(length);
    uint256 destPtr;
    assembly {
        destPtr := add(result, 0x20)
    }

    uint8 first;
    assembly {
        first := byte(0, mload(sourcePtr))
    }
    if (first >= 0x61 && first <= 0x7A) {
        first -= 0x20;
    }

    assembly {
        mstore8(destPtr, first)
    }

    if (length > 1) {
        // Copy the rest of the string
        for (uint256 i = 1; i < length; i++) {
            uint8 b;
            assembly {
                b := byte(0, mload(add(sourcePtr, i)))
            }
            assembly {
                mstore8(add(destPtr, i), b)
            }
        }
    }
    return result;
}

/**
 * @dev Returns true if the string slice contains no uppercase ASCII letters.
 */
function isLowerCaseEnglish(
    uint256 sourcePtr,
    uint256 length
) pure returns (bool) {
    for (uint256 i = 0; i < length; i++) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(sourcePtr, i)))
        }
        if (b >= 0x41 && b <= 0x5A) return false;
    }
    return true;
}

/**
 * @dev Returns true if the string slice contains no lowercase ASCII letters.
 */
function isUpperCaseEnglish(
    uint256 sourcePtr,
    uint256 length
) pure returns (bool) {
    for (uint256 i = 0; i < length; i++) {
        uint8 b;
        assembly {
            b := byte(0, mload(add(sourcePtr, i)))
        }
        if (b >= 0x61 && b <= 0x7A) return false;
    }
    return true;
}
