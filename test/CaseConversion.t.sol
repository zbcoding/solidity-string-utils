// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {PRBTest} from "@prb/test/src/PRBTest.sol";
import {StrSliceAssertions} from "../src/test/StrSliceAssertions.sol";
import {StrSlice, toSlice, StrSlice__InvalidCharBoundary} from "../src/StrSlice.sol";

contract CaseConversionTest is PRBTest, StrSliceAssertions {
    using {toSlice} for string;

    function testToUpperCaseEnglish() public {
        assertEq(toSlice("abc").toUpperCaseEnglish(), "ABC");
        assertEq(toSlice("ABC").toUpperCaseEnglish(), "ABC");
        assertEq(toSlice("123!@#").toUpperCaseEnglish(), "123!@#");
        assertEq(toSlice("abc ABC 123").toUpperCaseEnglish(), "ABC ABC 123");

        // Handling multi-byte characters safely
        assertEq(
            toSlice(unicode"📎!こんにちは").toUpperCaseEnglish(),
            unicode"📎!こんにちは"
        );
        assertEq(toSlice(unicode"café").toUpperCaseEnglish(), unicode"CAFé");
    }

    function testToLowerCaseEnglish() public {
        assertEq(toSlice("ABC").toLowerCaseEnglish(), "abc");
        assertEq(toSlice("abc").toLowerCaseEnglish(), "abc");
        assertEq(toSlice("123!@#").toLowerCaseEnglish(), "123!@#");
        assertEq(toSlice("abc ABC 123").toLowerCaseEnglish(), "abc abc 123");

        // Handling multi-byte characters safely
        assertEq(
            toSlice(unicode"📎!こんにちは").toLowerCaseEnglish(),
            unicode"📎!こんにちは"
        );
        assertEq(toSlice(unicode"CAFÉ").toLowerCaseEnglish(), unicode"cafÉ");
    }

    function testCaseConversionMixed() public {
        string memory input = "Hello World! 123";
        assertEq(toSlice(input).toUpperCaseEnglish(), "HELLO WORLD! 123");
        assertEq(toSlice(input).toLowerCaseEnglish(), "hello world! 123");
    }

    function testCapitalizeEnglish() public {
        assertEq(toSlice("alice").capitalizeEnglish(), "Alice");
        assertEq(toSlice("Alice").capitalizeEnglish(), "Alice");
        assertEq(toSlice("123").capitalizeEnglish(), "123");
        assertEq(toSlice("").capitalizeEnglish(), "");
        assertEq(
            toSlice(unicode"📎alice").capitalizeEnglish(),
            unicode"📎alice"
        );
    }

    function testEqualsIgnoreCaseEnglish() public {
        assertTrue(toSlice("Alice").equalsIgnoreCaseEnglish(toSlice("alice")));
        assertTrue(toSlice("ALICE").equalsIgnoreCaseEnglish(toSlice("alice")));
        assertTrue(toSlice("alice").equalsIgnoreCaseEnglish(toSlice("alice")));
        assertFalse(toSlice("Alice").equalsIgnoreCaseEnglish(toSlice("Bob")));
        assertTrue(
            toSlice("123!@#").equalsIgnoreCaseEnglish(toSlice("123!@#"))
        );

        // ensure range check works (not just bit flip)
        // '[' is 0x5B, '{' is 0x7B. 0x5B ^ 0x7B == 0x20
        assertFalse(toSlice("[").equalsIgnoreCaseEnglish(toSlice("{")));
    }

    function testIsLowerCaseEnglish() public {
        assertTrue(toSlice("alice").isLowerCaseEnglish());
        assertTrue(toSlice("alice 123!").isLowerCaseEnglish());
        assertFalse(toSlice("Alice").isLowerCaseEnglish());
        assertFalse(toSlice("ALICE").isLowerCaseEnglish());
    }

    function testIsUpperCaseEnglish() public {
        assertTrue(toSlice("ALICE").isUpperCaseEnglish());
        assertTrue(toSlice("ALICE 123!").isUpperCaseEnglish());
        assertFalse(toSlice("Alice").isUpperCaseEnglish());
        assertFalse(toSlice("alice").isUpperCaseEnglish());
    }
}
