// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {PRBTest} from "@prb/test/src/PRBTest.sol";
import {StrSliceAssertions} from "../src/test/StrSliceAssertions.sol";
import {StrSlice, toSlice, StrSlice__InvalidCharBoundary, toHexString} from "../src/StrSlice.sol";

contract ExtendedFeaturesTest is PRBTest, StrSliceAssertions {
    using {toSlice} for string;

    function testTrimming() public {
        assertEq(toSlice("  hello  ").trim().toString(), "hello");
        assertEq(toSlice("\t\n hello \r").trim().toString(), "hello");
        assertEq(toSlice("hello").trim().toString(), "hello");
        assertEq(toSlice("  ").trim().toString(), "");

        assertEq(toSlice("  hello").trimStart().toString(), "hello");
        assertEq(toSlice("hello  ").trimEnd().toString(), "hello");
    }

    function testParsing() public {
        assertEq(toSlice("123").toUint(), 123);
        assertEq(toSlice("0").toUint(), 0);

        address expected = 0x1234567890AbcdEF1234567890aBcdef12345678;
        assertEq(
            toSlice("0x1234567890AbcdEF1234567890aBcdef12345678").toAddress(),
            expected
        );
        assertEq(
            toSlice("1234567890AbcdEF1234567890aBcdef12345678").toAddress(),
            expected
        );
    }

    function testFormatting() public {
        assertEq(toSlice("a").repeat(3), "aaa");
        assertEq(toSlice("abc").repeat(2), "abcabc");
        assertEq(toSlice("abc").repeat(0), "");

        assertEq(toSlice("1").padLeft(3, "0"), "001");
        assertEq(toSlice("1").padRight(3, "0"), "100");
        assertEq(toSlice("long").padLeft(2, "x"), "long");
    }

    function testHexConversion() public {
        // uint256.toHexString is global
        uint256 val = 0x123;
        assertEq(toHexString(val), "0x0123");
        assertEq(toHexString(uint256(0)), "0x00");
    }

    function testSplitAndCount() public {
        StrSlice s = toSlice("a,b,c");
        assertEq(s.count(toSlice(",")), 2);

        StrSlice[] memory parts = s.split(toSlice(","));
        assertEq(parts.length, 3);
        assertEq(parts[0].toString(), "a");
        assertEq(parts[1].toString(), "b");
        assertEq(parts[2].toString(), "c");

        StrSlice[] memory single = toSlice("abc").split(toSlice(","));
        assertEq(single.length, 1);
        assertEq(single[0].toString(), "abc");
    }
}
