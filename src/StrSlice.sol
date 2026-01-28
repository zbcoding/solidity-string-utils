// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Slice, Slice__, Slice__OutOfBounds} from "./Slice.sol";
import {StrChar, StrChar__} from "./StrChar.sol";
import {StrCharsIter, StrCharsIter__} from "./StrCharsIter.sol";
import {isValidUtf8} from "./utils/utf8.sol";
import {memIsAscii} from "./utils/memascii.sol";
import {toUpperCaseEnglish as _toUpperCaseEnglish, toLowerCaseEnglish as _toLowerCaseEnglish, equalsIgnoreCaseEnglish as _equalsIgnoreCaseEnglish, capitalizeEnglish as _capitalizeEnglish, isLowerCaseEnglish as _isLowerCaseEnglish, isUpperCaseEnglish as _isUpperCaseEnglish} from "./utils/ascii.sol";
import {trim as _trim, trimStart as _trimStart, trimEnd as _trimEnd} from "./utils/trim.sol";
import {toUint as _toUint, toAddress as _toAddress} from "./utils/parse.sol";
import {repeat as _repeat, padLeft as _padLeft, padRight as _padRight, toHexString as _toHexString} from "./utils/format.sol";
import {PackPtrLen} from "./utils/PackPtrLen.sol";

/**
 * @title A string slice.
 * @dev String slices must always be valid UTF-8.
 * Internally `StrSlice` uses `Slice`, adding only UTF-8 related logic on top.
 */
type StrSlice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrSlice__InvalidCharBoundary();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrSlice__ {
    /**
     * @dev Converts a `string` to a `StrSlice`.
     * The string is not copied.
     * `StrSlice` points to the memory of `string`, right after the length word.
     */
    function from(string memory str) internal pure returns (StrSlice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(str, 0x20)
        }
        return fromRawParts(_ptr, bytes(str).length);
    }

    /**
     * @dev Creates a new `StrSlice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(
        uint256 _ptr,
        uint256 _len
    ) internal pure returns (StrSlice slice) {
        return StrSlice.wrap(Slice.unwrap(Slice__.fromRawParts(_ptr, _len)));
    }

    /**
     * @dev Returns true if the byte slice starts with a valid UTF-8 character.
     * Note this does not validate the whole slice.
     */
    function isBoundaryStart(Slice slice) internal pure returns (bool) {
        bytes32 b = slice.toBytes32();
        return isValidUtf8(b) != 0;
    }
}

/**
 * @dev Alternative to StrSlice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for string;
 * ```
 */
function toSlice(string memory str) pure returns (StrSlice slice) {
    return StrSlice__.from(str);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asSlice,
    ptr,
    len,
    isEmpty,
    toString,
    keccak,
    add,
    join,
    cmp,
    eq,
    ne,
    lt,
    lte,
    gt,
    gte,
    isCharBoundary,
    get,
    splitAt,
    getSubslice,
    find,
    rfind,
    contains,
    startsWith,
    endsWith,
    stripPrefix,
    stripSuffix,
    splitOnce,
    rsplitOnce,
    replacen,
    chars,
    isAscii,
    toUpperCaseEnglish,
    toLowerCaseEnglish,
    equalsIgnoreCaseEnglish,
    capitalizeEnglish,
    isLowerCaseEnglish,
    isUpperCaseEnglish,
    trim,
    trimStart,
    trimEnd,
    toUint,
    toAddress,
    repeat,
    padLeft,
    padRight,
    count,
    split
} for StrSlice global;

using {toHexString} for uint256;

/**
 * @dev Returns the underlying `Slice`.
 * WARNING: manipulating `Slice`s can break UTF-8 for related `StrSlice`s!
 */
function asSlice(StrSlice self) pure returns (Slice) {
    return Slice.wrap(StrSlice.unwrap(self));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(StrSlice self) pure returns (bool) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `StrSlice` to a newly allocated string.
 * The `StrSlice` will NOT point to the new string.
 */
function toString(StrSlice self) view returns (string memory) {
    return string(self.asSlice().toBytes());
}

/**
 * @dev Returns keccak256 of all the bytes of `StrSlice`.
 * Note that for any `string memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(StrSlice self) pure returns (bytes32 result) {
    return self.asSlice().keccak();
}

/**
 * @dev Concatenates two `StrSlice`s into a newly allocated string.
 */
function add(StrSlice self, StrSlice other) view returns (string memory) {
    return string(self.asSlice().add(other.asSlice()));
}

/**
 * @dev Flattens an array of `StrSlice`s into a single newly allocated string,
 * placing `self` as the separator between each.
 */
function join(
    StrSlice self,
    StrSlice[] memory strs
) view returns (string memory) {
    Slice[] memory slices;
    assembly {
        slices := strs
    }
    return string(self.asSlice().join(slices));
}

/**
 * @dev Compare string slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrSlice self, StrSlice other) pure returns (int256 result) {
    return self.asSlice().cmp(other.asSlice());
}

/// @dev `self` == `other`
/// Note more efficient than cmp
function eq(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().eq(other.asSlice());
}

/// @dev `self` != `other`
/// Note more efficient than cmp
function ne(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().ne(other.asSlice());
}

/// @dev `self` < `other`
function lt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Checks that `index`-th byte is safe to split on.
 * The start and end of the string (when index == self.len()) are considered to be boundaries.
 * Returns false if index is greater than self.len().
 */
function isCharBoundary(StrSlice self, uint256 index) pure returns (bool) {
    if (index < self.len()) {
        return isValidUtf8(self.asSlice().getAfter(index).toBytes32()) != 0;
    } else if (index == self.len()) {
        return true;
    } else {
        return false;
    }
}

/**
 * @dev Returns the character at `index` (in bytes).
 * Reverts if index is out of bounds.
 */
function get(StrSlice self, uint256 index) pure returns (StrChar char) {
    bytes32 b = self.asSlice().getAfterStrict(index).toBytes32();
    uint256 charLen = isValidUtf8(b);
    if (charLen == 0) revert StrSlice__InvalidCharBoundary();
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Divides one string slice into two at an index.
 * Reverts when splitting on a non-boundary (use isCharBoundary).
 */
function splitAt(StrSlice self, uint256 mid) pure returns (StrSlice, StrSlice) {
    (Slice lSlice, Slice rSlice) = self.asSlice().splitAt(mid);
    if (
        !StrSlice__.isBoundaryStart(lSlice) ||
        !StrSlice__.isBoundaryStart(rSlice)
    ) {
        revert StrSlice__InvalidCharBoundary();
    }
    return (
        StrSlice.wrap(Slice.unwrap(lSlice)),
        StrSlice.wrap(Slice.unwrap(rSlice))
    );
}

/**
 * @dev Returns a subslice [start..end) of `self`.
 * Reverts when slicing a non-boundary (use isCharBoundary).
 */
function getSubslice(
    StrSlice self,
    uint256 start,
    uint256 end
) pure returns (StrSlice) {
    Slice subslice = self.asSlice().getSubslice(start, end);
    if (!StrSlice__.isBoundaryStart(subslice))
        revert StrSlice__InvalidCharBoundary();
    if (end != self.len()) {
        (, Slice nextSubslice) = self.asSlice().splitAt(end);
        if (!StrSlice__.isBoundaryStart(nextSubslice))
            revert StrSlice__InvalidCharBoundary();
    }
    return StrSlice.wrap(Slice.unwrap(subslice));
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().find(pattern.asSlice());
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().rfind(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this string slice.
 */
function contains(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().contains(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a prefix of this string slice.
 */
function startsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().startsWith(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a suffix of this string slice.
 */
function endsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().endsWith(pattern.asSlice());
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(
    StrSlice self,
    StrSlice pattern
) pure returns (StrSlice result) {
    return
        StrSlice.wrap(
            Slice.unwrap(self.asSlice().stripPrefix(pattern.asSlice()))
        );
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(
    StrSlice self,
    StrSlice pattern
) pure returns (StrSlice result) {
    return
        StrSlice.wrap(
            Slice.unwrap(self.asSlice().stripSuffix(pattern.asSlice()))
        );
}

/**
 * @dev Splits a slice into 2 on the first match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be the entire string and `suffix` will be empty.
 */
function splitOnce(
    StrSlice self,
    StrSlice pattern
) pure returns (bool found, StrSlice prefix, StrSlice suffix) {
    uint256 index = self.asSlice().find(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, self, StrSlice.wrap(0));
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * @dev Splits a slice into 2 on the last match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be empty and `suffix` will be the entire string.
 */
function rsplitOnce(
    StrSlice self,
    StrSlice pattern
) pure returns (bool found, StrSlice prefix, StrSlice suffix) {
    uint256 index = self.asSlice().rfind(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, StrSlice.wrap(0), self);
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * *EXPERIMENTAL*
 * @dev Replaces first `n` matches of a pattern with another string slice.
 * Returns the result in a newly allocated string.
 * Note this does not modify the string `self` is a slice of.
 * WARNING: Requires 0 < pattern.len() <= to.len()
 */
function replacen(
    StrSlice self,
    StrSlice pattern,
    StrSlice to,
    uint256 n
) view returns (string memory str) {
    uint256 patLen = pattern.len();
    uint256 toLen = to.len();
    // TODO dynamic string; atm length can be reduced but not increased
    assert(patLen >= toLen);
    assert(patLen > 0);

    str = new string(self.len());
    Slice iterSlice = self.asSlice();
    Slice resultSlice = Slice__.from(bytes(str));

    uint256 matchNum;
    while (matchNum < n) {
        uint256 index = iterSlice.find(pattern.asSlice());
        // break if no more matches
        if (index == type(uint256).max) break;
        // copy prefix
        if (index > 0) {
            resultSlice.getBefore(index).copyFromSlice(
                iterSlice.getBefore(index)
            );
        }

        uint256 indexToEnd;
        // TODO this is fine atm only because patLen <= toLen
        unchecked {
            indexToEnd = index + toLen;
        }

        // copy replacement
        resultSlice.getSubslice(index, indexToEnd).copyFromSlice(to.asSlice());

        // advance slices past the match
        iterSlice = iterSlice.getAfter(index + patLen);
        resultSlice = resultSlice.getAfter(indexToEnd);

        // break if iterSlice is done
        if (iterSlice.len() == 0) {
            break;
        }
        // safe because of `while` condition
        unchecked {
            matchNum++;
        }
    }

    uint256 realLen = resultSlice.ptr() - StrSlice__.from(str).ptr();
    // copy suffix
    uint256 iterLen = iterSlice.len();
    if (iterLen > 0) {
        resultSlice.getBefore(iterLen).copyFromSlice(iterSlice);
        realLen += iterLen;
    }
    // remove extra length
    if (bytes(str).length != realLen) {
        // TODO atm only accepting patLen <= toLen
        assert(realLen <= bytes(str).length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, realLen)
        }
    }
    return str;
}

/**
 * @dev Returns an character iterator over the slice.
 * The iterator yields items from either side.
 */
function chars(StrSlice self) pure returns (StrCharsIter memory) {
    return StrCharsIter(self.ptr(), self.len());
}

/**
 * @dev Checks if all characters are within the ASCII range.
 *
 * Note this does NOT explicitly validate UTF-8.
 * Whereas ASCII certainly is valid UTF-8, non-ASCII *could* be invalid UTF-8.
 * Use `StrCharsIter` for explicit validation.
 */
function isAscii(StrSlice self) pure returns (bool) {
    return memIsAscii(self.ptr(), self.len());
}

/**
 * @dev Returns a new string with all ASCII lowercase letters converted to uppercase.
 * Non-ASCII characters are left unchanged.
 *
 * This function performs a single pass over the string and allocates a new string.
 */
function toUpperCaseEnglish(StrSlice self) view returns (string memory) {
    return _toUpperCaseEnglish(self.ptr(), self.len());
}

/**
 * @dev Returns a new string with all ASCII uppercase letters converted to lowercase.
 * Non-ASCII characters are left unchanged.
 *
 * This function performs a single pass over the string and allocates a new string.
 */
function toLowerCaseEnglish(StrSlice self) view returns (string memory) {
    return _toLowerCaseEnglish(self.ptr(), self.len());
}

/**
 * @dev Returns true if two string slices are equal regardless of case.
 * Only handles ASCII letters (a-z, A-Z).
 *
 * This is more gas-efficient than converting both strings to the same case
 * and then comparing, as it performs a single pass without extra allocations.
 */
function equalsIgnoreCaseEnglish(
    StrSlice self,
    StrSlice other
) pure returns (bool) {
    return
        _equalsIgnoreCaseEnglish(
            self.ptr(),
            self.len(),
            other.ptr(),
            other.len()
        );
}

/**
 * @dev Returns a new string with the first ASCII character capitalized.
 */
function capitalizeEnglish(StrSlice self) view returns (string memory) {
    return _capitalizeEnglish(self.ptr(), self.len());
}

/**
 * @dev Returns true if the string slice contains no uppercase ASCII letters.
 */
function isLowerCaseEnglish(StrSlice self) pure returns (bool) {
    return _isLowerCaseEnglish(self.ptr(), self.len());
}

/**
 * @dev Returns true if the string slice contains no lowercase ASCII letters.
 */
function isUpperCaseEnglish(StrSlice self) pure returns (bool) {
    return _isUpperCaseEnglish(self.ptr(), self.len());
}

/**
 * @dev Returns a subslice with leading and trailing whitespace removed.
 *
 * This is extremely gas-efficient as it only moves the pointer and
 * decreases the length, requiring NO new memory allocation.
 */
function trim(StrSlice self) pure returns (StrSlice) {
    (uint256 p, uint256 l) = _trim(self.ptr(), self.len());
    return StrSlice__.fromRawParts(p, l);
}

/**
 * @dev Returns a subslice with leading whitespace removed.
 *
 * This is extremely gas-efficient as it only moves the pointer and
 * decreases the length, requiring NO new memory allocation.
 */
function trimStart(StrSlice self) pure returns (StrSlice) {
    (uint256 p, uint256 l) = _trimStart(self.ptr(), self.len());
    return StrSlice__.fromRawParts(p, l);
}

/**
 * @dev Returns a subslice with trailing whitespace removed.
 *
 * This is extremely gas-efficient as it only adjusts the length,
 * requiring NO new memory allocation.
 */
function trimEnd(StrSlice self) pure returns (StrSlice) {
    (uint256 p, uint256 l) = _trimEnd(self.ptr(), self.len());
    return StrSlice__.fromRawParts(p, l);
}

/**
 * @dev Converts a numeric ASCII string slice to a uint256.
 */
function toUint(StrSlice self) pure returns (uint256) {
    return _toUint(self.ptr(), self.len());
}

/**
 * @dev Converts a hex string slice to an address.
 */
function toAddress(StrSlice self) pure returns (address) {
    return _toAddress(self.ptr(), self.len());
}

/**
 * @dev Returns a new string by repeating the slice `n` times.
 */
function repeat(StrSlice self, uint256 n) view returns (string memory) {
    return _repeat(self.ptr(), self.len(), n);
}

/**
 * @dev Pads the slice on the left with `char` to reach `totalLen`.
 */
function padLeft(
    StrSlice self,
    uint256 totalLen,
    bytes1 char
) view returns (string memory) {
    return _padLeft(self.ptr(), self.len(), totalLen, char);
}

/**
 * @dev Pads the slice on the right with `char` to reach `totalLen`.
 */
function padRight(
    StrSlice self,
    uint256 totalLen,
    bytes1 char
) view returns (string memory) {
    return _padRight(self.ptr(), self.len(), totalLen, char);
}

/**
 * @dev Converts a uint256 to its hex string representation (0x prefixed).
 */
function toHexString(uint256 value) pure returns (string memory) {
    return _toHexString(value);
}

/**
 * @dev Returns the number of non-overlapping occurrences of `pattern` in `self`.
 */
function count(StrSlice self, StrSlice pattern) pure returns (uint256 counter) {
    Slice haystack = self.asSlice();
    Slice pat = pattern.asSlice();
    uint256 patLen = pat.len();
    if (patLen == 0) return self.len() + 1;

    while (true) {
        uint256 index = haystack.find(pat);
        if (index == type(uint256).max) break;
        counter++;
        haystack = haystack.getAfter(index + patLen);
    }
}

/**
 * @dev Splits a slice into an array of sections, separated by `delimiter`.
 */
function split(
    StrSlice self,
    StrSlice delimiter
) pure returns (StrSlice[] memory results) {
    uint256 delimLen = delimiter.len();
    if (delimLen == 0) {
        results = new StrSlice[](1);
        results[0] = self;
        return results;
    }

    uint256 numParts = self.count(delimiter) + 1;
    results = new StrSlice[](numParts);

    StrSlice haystack = self;
    for (uint256 i = 0; i < numParts - 1; i++) {
        (bool found, StrSlice prefix, StrSlice suffix) = haystack.splitOnce(
            delimiter
        );
        results[i] = prefix;
        haystack = suffix;
    }
    results[numParts - 1] = haystack;
}

/*//////////////////////////////////////////////////////////////////////////
                              FILE FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {_splitFound} for StrSlice;

/**
 * @dev Splits a slice into [:index] and [index+patLen:].
 * CALLER GUARANTEE: `index` < self.len()
 * For internal use by split/rsplit.
 *
 * This is mostly just a faster alternative to `getBefore`+`getAfter`.
 */
function _splitFound(
    StrSlice self,
    uint256 index,
    uint256 patLen
) pure returns (bool, StrSlice prefix, StrSlice suffix) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    uint256 indexAfterPat;
    // safe because caller guarantees index to be < selfLen
    unchecked {
        indexAfterPat = index + patLen;
        if (indexAfterPat > selfLen) revert Slice__OutOfBounds();
    }
    // [:index] (inlined `getBefore`)
    prefix = StrSlice.wrap(Slice.unwrap(Slice__.fromUnchecked(selfPtr, index)));
    // [(index+patLen):] (inlined `getAfter`)
    // safe because indexAfterPat <= selfLen
    unchecked {
        suffix = StrSlice.wrap(
            Slice.unwrap(
                Slice__.fromUnchecked(
                    selfPtr + indexAfterPat,
                    selfLen - indexAfterPat
                )
            )
        );
    }
    return (true, prefix, suffix);
}
