# String library for Solidity (Work in progress)

- Types: [StrSlice](src/StrSlice.sol) for strings, [Slice](src/Slice.sol) for bytes, [StrChar](src/StrChar.sol) for characters
- Gas efficient (see [gas benchmarks](https://github.com/dk1a/solidity-stringutils-gas))
- Versioned releases, available for both foundry and hardhat
- Simple imports, you only need e.g. `StrSlice` and `toSlice`
- `StrSlice` enforces UTF-8 character boundaries; `StrChar` validates character encoding
- Clean, well-documented and thoroughly-tested source code
- Optional [PRBTest](https://github.com/paulrberg/prb-test) extension with assertions like `assertContains` and `assertLt` for both slices and native `bytes`, `string`
- `Slice` and `StrSlice` are value types, not structs
- Low-level functions like [memchr](src/utils/memchr.sol), [memcmp, memmove etc](src/utils/mem.sol)


## When to Use This Library

### ⚠️ Why do Ethereum devs frown upon strings?
Gas costs - Strings are expensive.

- Storage: Storing strings on-chain costs ~20,000 gas per 32-byte slot. A microblog-length string could cost $5-50+ depending on gas prices
- Operations: String comparison, concatenation, and manipulation require loops over bytes—each iteration costs gas
- Memory expansion: Longer strings expand memory, which has quadratic cost growth
- No native support: Solidity has no built-in string functions, so any operation requires library code (more bytecode = higher deployment cost)
- Determinism concerns - Strings introduce complexity:
  - Variable length makes gas estimation unpredictable
  - UTF-8 encoding edge cases can cause unexpected behavior
  - Comparison/sorting depends on encoding, not semantic meaning

**Best practice alternatives:**

| Instead of... | Use... |
|---------------|--------|
| String identifiers | `bytes32` (fixed, cheap comparison) |
| String enums | `uint8` enum types |
| User-facing text | Events (logged off-chain, much cheaper) |
| Configuration | Off-chain storage with on-chain hash verification |


### Where String Utils Shines

Despite gas concerns, there are excellent use cases for on-chain string manipulation:

#### 1. View Functions & Off-Chain Reads (No Gas Cost)
- Input validation in view functions
- Formatting data for front-end consumption
- ABI encoding helpers

#### 2. L2 and Alternative Chains
Gas on L2s (Arbitrum, Optimism, Base) is **10-100x cheaper** than mainnet. On app-specific chains, it's often negligible.

#### 3. Testing & Development
- Assertion helpers for test suites (included!)
- Fuzzing utilities for string inputs
- Console.log formatting in Foundry

#### 4. High-Value String Operations
Some operations justify the gas cost:
- **EIP-712 signature formatting** — Structured data often requires string building
- **NFT/Token URI construction** — Dynamic metadata URIs
- **Rich revert messages** — Debugging with dynamic error content
- **Merkle proof data** — String-based allowlists

#### 5. Parsing User Input
Convert strings to native types:
- `toUint()` — Parse numeric strings
- `toAddress()` — Parse hex addresses (with or without `0x` prefix)

### The Future: Why Strings Could Matter More

Future development could lower the gas cost of strings, making them more viable.

| Trend | Impact |
|-------|--------|
| **L2 Scaling** | Already 100x cheaper, heading toward negligible |
| **EIP-4844 (Blobs)** | Dramatically reduces data availability costs |
| **Verkle Trees** | Will reduce state access costs |
| **Account Abstraction** | Gas sponsorship means users don't feel costs |
| **App-Specific Chains** | Gaming/social chains prioritize UX over minimal gas |

**Emerging use cases:**
- On-chain social profiles and content
- Rich metadata stored directly in contracts
- Human-readable governance proposals
- On-chain search and indexing

### Quick Decision Guide

**Use this library when:**
- You're on an L2 or low-cost chain
- You're building view functions or off-chain tooling
- You need URI construction, input parsing, or rich error messages
- You're writing tests
- You've planned for gas costs or are not worried about gas costs

**Think twice when:**
- You're on a circa 2025 EVM with cost-sensitive users
- A `bytes32` or enum would suffice
- The string could live off-chain with only a hash on-chain

## Gas Optimization Notes

[Solidity String Utils Gas Measurements](https://github.com/dk1a/solidity-stringutils-gas) note that the original [Arachnid implementation](https://github.com/Arachnid/solidity-stringutils) was designed before Solidity 0.8.0, and doesn't use code in unchecked blocks to significantly reduce gas costs.

Standard forge gas snapshots don't capture string/bytes function efficiency well—they're not suited for internal functions with dynamic inputs where gas varies significantly (e.g., finding an item at index 0 vs index 500 in a 1000-byte string).

See the [gas benchmarks repo](https://github.com/dk1a/solidity-stringutils-gas) for detailed measurements.

### Performance Characteristics

| Operation | Best For | Notes |
|-----------|----------|-------|
| `memchr`, `find` | Strings > ~8 bytes | Optimized for long strings; binary search tricks for 8-32 bytes |
| `memcmp` (inequality) | Long strings | For 10,000+ bytes, approaches `keccak256` hash comparison speed |
| `memmove` | Fast copying (view) | Uses identity precompile; very efficient but requires `view` |
| `memcpy` | Pure copying | Chunked `mload`/`mstore`; slower but `pure` compatible |
| `StrCharsIter.count` | Validated counting | Slower—must validate every UTF-8 character |
| `StrCharsIter.unsafeCount` | Fast counting | Very fast—no validation (equivalent to Arachnid's `len`) |

### Trade-offs in This Library

**Optimized for longer strings:** Short strings (~8 bytes) have proportionally more overhead from safety checks like `len()` and `ptr()` (~50 gas each). This overhead is a deliberate trade-off for usability and readability.

**Why some methods are `view`:** Methods using `memmove` (identity precompile) are `view` because the precompile isn't `pure`. The `pure` alternative `memcpy` is available but slower.

**UTF-8 validation costs:** Safe iteration via `StrCharsIter` validates encoding. Use `unsafeCount` when you trust the input and need speed.

### Direct Low-Level Access

For maximum efficiency, use the low-level utilities directly:
- [memchr](src/utils/memchr.sol) — byte search
- [memcmp, memmove, memcpy](src/utils/mem.sol) — memory operations

These have minimal overhead and are suitable for performance-critical code.

## Solidity String Limitations

Solidity does **not** provide native string manipulation functions such as
`substring`, `slice`, `indexOf`, or `split`. There is no built-in way to slice
strings directly (for example, `str.substring(1, 5)` is not supported).

### Available Approaches

- **Work with `bytes`**  
  Strings are UTF-8, but `bytes` are indexable, which allows manual byte-level
  slicing.  
  ⚠️ This operates on bytes, **not Unicode characters**, and may break on
  multi-byte UTF-8 characters.

- **Use a `solidity-stringutils` library **  
  This library exists to fill the gap, providing slicing, substring search,
  and comparison utilities via a `slice` abstraction.  
  This is the closest thing to real substring support in Solidity.

- **Concatenation only (built-in)**  
  Solidity `0.8.12+` supports `string.concat(...)`, but still offers **no**
  slicing or parsing functionality. Solidity has slowly been adding more string functions.

### ⚠️ Design & Gas Considerations

- String manipulation is **gas-expensive**
- UTF-8 handling is error-prone on-chain
- Best practice is to **avoid string parsing on-chain**
- Prefer `bytes32`, enums, IDs, or hashes
- Perform complex string operations **off-chain** when possible

### Key points:

- ❌ No native substring support in Solidity  
- ✅ Possible via `bytes` or libraries  
- ⚠️ Byte-based, not Unicode-safe  
- 🧠 Often better to redesign than parse strings on-chain

## StrSlice

```solidity
import { StrSlice, toSlice } from "solidity-stringutils/src/StrSlice.sol";

using { toSlice } for string;

/// @dev Returns the content of brackets, or empty string if not found
function extractFromBrackets(string memory stuffInBrackets) pure returns (StrSlice extracted) {
    StrSlice s = stuffInBrackets.toSlice();
    bool found;

    (found, , s) = s.splitOnce(toSlice("("));
    if (!found) return toSlice("");

    (found, s, ) = s.rsplitOnce(toSlice(")"));
    if (!found) return toSlice("");

    return s;
}
/*
assertEq(
    extractFromBrackets("((1 + 2) + 3) + 4"),
    toSlice("(1 + 2) + 3")
);
*/
```

See [ExamplesTest](test/Examples.t.sol).

Internally `StrSlice` uses `Slice` and extends it with logic for multibyte UTF-8 where necessary.

| Method           | Description                                      |
| ---------------- | ------------------------------------------------ |
| `len`            | length in **bytes**                              |
| `isEmpty`        | true if len == 0                                 |
| `toString`       | copy slice contents to a **new** string          |
| `keccak`         | equal to `keccak256(s.toString())`, but cheaper  |
**concatenate**
| `add`            | Concatenate 2 slices into a **new** string       |
| `join`           | Join slice array on `self` as separator          |
**compare**
| `cmp`            | 0 for eq, < 0 for lt, > 0 for gt                 |
| `eq`,`ne`        | ==, !=  (more efficient than cmp)                |
| `lt`,`lte`       | <, <=                                            |
| `gt`,`gte`       | >, >=                                            |
**index**
| `isCharBoundary` | true if given index is an allowed boundary       |
| `get`            | get 1 UTF-8 character at given index             |
| `splitAt`        | (slice[:index], slice[index:])                   |
| `getSubslice`    | slice[start:end]                                 |
**search**
| `find`           | index of the start of the **first** match        |
| `rfind`          | index of the start of the **last** match         |
|                  | *return `type(uint256).max` for no matches*      |
| `contains`       | true if a match is found                         |
| `startsWith`     | true if starts with pattern                      |
| `endsWith`       | true if ends with pattern                        |
**modify**
| `stripPrefix`    | returns subslice without the prefix              |
| `stripSuffix`    | returns subslice without the suffix              |
| `splitOnce`      | split into 2 subslices on the **first** match    |
| `rsplitOnce`     | split into 2 subslices on the **last** match     |
| `replacen`       | *experimental* replace `n` matches               |
|                  | *replacen requires 0 < pattern.len() <= to.len()*|
**iterate**
| `chars`          | character iterator over the slice                |
**ascii**
| `isAscii`        | true if all chars are ASCII                      |
**dangerous**
| `asSlice`        | get underlying Slice                             |
| `ptr`            | get memory pointer                               |
**case conversion**
| `toUpperCaseEnglish` | get new string with A-Z                     |
| `toLowerCaseEnglish` | get new string with a-z                     |
| `capitalizeEnglish`  | get new string with first char capitalized   |
| `equalsIgnoreCaseEnglish` | true if equal ignoring case              |
| `isLowerCaseEnglish` | true if contains no uppercase A-Z             |
| `isUpperCaseEnglish` | true if contains no lowercase a-z             |
|                  | *non-ASCII chars are left unchanged*             |
**trimming**
| `trim`           | remove leading and trailing whitespace           |
| `trimStart`      | remove leading whitespace                        |
| `trimEnd`        | remove trailing whitespace                       |
**parsing**
| `toUint`         | parse ASCII numeric string to uint256            |
| `toAddress`      | parse hex string to address                      |
**formatting**
| `repeat`         | repeat slice N times into a new string           |
| `padLeft`        | pad left to totalLen with char                   |
| `padRight`       | pad right to totalLen with char                  |
| `toHexString`    | convert uint256 or bytes to "0x..." string       |
**search & split**
| `count`          | count non-overlapping matches                    |
| `split`          | split into StrSlice[] array by delimiter         |

Indexes are in **bytes**, not characters. Indexing methods revert if `isCharBoundary` is false.

## StrCharsIter

*Returned by `chars` method of `StrSlice`*

```solidity
import { StrSlice, toSlice, StrCharsIter } from "@dk1a/solidity-stringutils/src/StrSlice.sol";

using { toSlice } for string;

/// @dev Returns a StrSlice of `str` with the 2 first UTF-8 characters removed
/// reverts on invalid UTF8
function removeFirstTwoChars(string memory str) pure returns (StrSlice) {
    StrCharsIter memory chars = str.toSlice().chars();
    for (uint256 i; i < 2; i++) {
        if (chars.isEmpty()) break;
        chars.next();
    }
    return chars.asStr();
}
/*
assertEq(removeFirstTwoChars(unicode"📎!こんにちは"), unicode"こんにちは");
*/
```

| Method           | Description                                      |
| ---------------- | ------------------------------------------------ |
| `asStr`          | get underlying StrSlice of the remainder         |
| `len`            | remainder length in **bytes**                    |
| `isEmpty`        | true if len == 0                                 |
| `next`           | advance the iterator, return the next StrChar    |
| `nextBack`       | advance from the back, return the next StrChar   |
| `count`          | returns the number of UTF-8 characters           |
| `validateUtf8`   | returns true if the sequence is valid UTF-8      |
**dangerous**
| `unsafeNext`     | advance unsafely, return the next StrChar        |
| `unsafeCount`    | unsafely count chars, read the source for caveats|
| `ptr`            | get memory pointer                               |

`count`, `validateUtf8`, `unsafeCount` consume the iterator in O(n).

Safe methods revert on an invalid UTF-8 byte sequence.

`unsafeNext` does NOT check if the iterator is empty, may underflow! Does not revert on invalid UTF-8. If returned `StrChar` is invalid, it will have length 0. Otherwise length 1-4.

Internally `next`, `unsafeNext`, `count` all use `_nextRaw`. It's very efficient, but very unsafe and complicated. Read the source and import it separately if you need it.

## StrChar

Represents a single UTF-8 encoded character.
Internally it's bytes32 with leading byte at MSB.

It's returned by some methods of `StrSlice` and `StrCharsIter`.

| Method           | Description                                      |
| ---------------- | ------------------------------------------------ |
| `len`            | character length in bytes                        |
| `toBytes32`      | returns the underlying `bytes32` value           |
| `toString`       | copy the character to a new string               |
| `toCodePoint`    | returns the unicode code point (`ord` in python) |
| `cmp`            | 0 for eq, < 0 for lt, > 0 for gt                 |
| `eq`,`ne`        | ==, !=                                           |
| `lt`,`lte`       | <, <=                                            |
| `gt`,`gte`       | >, >=                                            |
| `isValidUtf8`    | usually true                                     |
| `isAscii`        | true if the char is ASCII                        |

Import `StrChar__` (static function lib) to use `StrChar__.fromCodePoint` for code point to `StrChar` conversion.

`len` can return `0` *only* for invalid UTF-8 characters. But some invalid chars *may* have non-zero len! (use `isValidUtf8` to check validity). Note that `0x00` is a valid 1-byte UTF-8 character, its len is 1.

`isValidUtf8` can be false if the character was formed with an unsafe method (fromUnchecked, wrap).

## Slice

```solidity
import { Slice, toSlice } from "solidity-stringutils/src/Slice.sol";

using { toSlice } for bytes;

function findZeroByte(bytes memory b) pure returns (uint256 index) {
    return b.toSlice().find(
        bytes(hex"00").toSlice()
    );
}
```

See `using {...} for Slice global` in the source for a function summary. Many are shared between `Slice` and `StrSlice`, but there are differences.

Internally Slice has very minimal assembly, instead using `memcpy`, `memchr`, `memcmp` and others; if you need the low-level functions, see `src/utils/`.

## Assertions (PRBTest extension)

```solidity
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Assertions } from "solidity-stringutils/src/test/Assertions.sol";

contract StrSliceTest is PRBTest, Assertions {
    function testContains() public {
        bytes memory b1 = "12345";
        bytes memory b2 = "3";
        assertContains(b1, b2);
    }

    function testLt() public {
        string memory s1 = "123";
        string memory s2 = "124";
        assertLt(s1, s2);
    }
}
```

You can completely ignore slices if all you want is e.g. `assertContains` for native `bytes`/`string`.

## Acknowledgements
- [dk1a/solidity-stringutils](https://github.com/dk1a/solidity-stringutils) - This library is a fork of dk1a's string utils.
- [Arachnid/solidity-stringutils](https://github.com/Arachnid/solidity-stringutils) - One of the first versions of solidity-stringutils
- [paulrberg/prb-math](https://github.com/paulrberg/prb-math) - good template for solidity data structure libraries with `using {...} for ... global`
- [brockelmore/memmove](https://github.com/brockelmore/memmove) - good assembly memory management examples
