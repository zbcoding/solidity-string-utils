# Changelog

## [1.0.0] - 2025-01-28

Initial release of this fork.

### Changes from upstream

- Removed npm/yarn packaging (distributed as zip/tar.gz)
- Updated import paths

### Features

(Add your new features here)

---

## Prior History (dk1a/solidity-stringutils)

This project is a fork of [dk1a/solidity-stringutils](https://github.com/dk1a/solidity-stringutils).
The following is the changelog from the original project up to v0.3.3.

### 0.3.3 (2023-01-18)

**Bug Fixes**
- Correct an annotation placement

**Features**
- **Slice:** add copyFromValue

### 0.3.1 (2022-12-15)

**Features**
- Add fast uint to string conversion
- Add isAscii

### 0.3.0 (2022-12-12)

**Features**
- Add optimizations to StrCharsIter, StrChar
- Add unicode code point support and tests for StrChar

### 0.2.2 (2022-12-11)

**Bug Fixes**
- Fix critical issues in SliceIter tests
- Fix critical issues with nextBack in StrCharsIter and its tests; add optimizations

### 0.2.0 (2022-12-09)

**Features**
- Add replacen
- Use memmove instead of memcpy

### 0.1.0 (2022-12-07)

**Bug Fixes**
- stripSuffix

**Features**
- Initial commit
- Add string slice, char, char iterator
- Add splitOnce
- Add getAfterStrict
- Add StrSlice assertions
