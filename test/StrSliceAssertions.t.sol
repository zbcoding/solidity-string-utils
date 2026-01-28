// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {PRBTest} from "@prb/test/src/PRBTest.sol";
import {StrSliceAssertions} from "../src/test/StrSliceAssertions.sol";

import {StrSlice, toSlice} from "../src/StrSlice.sol";

using {toSlice} for string;

/// @dev Helper contract to test assertion reverts via external calls
/// Note: We pass raw string data instead of StrSlice because memory pointers
/// don't survive external calls. Uses require() to ensure reverts propagate.
contract StrSliceAssertionsRevertHelper {
    using {toSlice} for string;

    function callAssertEq(string memory a, string memory b) external pure {
        require(a.toSlice().eq(b.toSlice()), "Slices not equal");
    }

    function callAssertNotEq(string memory a, string memory b) external pure {
        require(a.toSlice().ne(b.toSlice()), "Slices are equal");
    }

    function callAssertLt(string memory a, string memory b) external pure {
        require(a.toSlice().lt(b.toSlice()), "a not less than b");
    }

    function callAssertLte(string memory a, string memory b) external pure {
        require(a.toSlice().lte(b.toSlice()), "a not less than or equal to b");
    }

    function callAssertGt(string memory a, string memory b) external pure {
        require(a.toSlice().gt(b.toSlice()), "a not greater than b");
    }

    function callAssertGte(string memory a, string memory b) external pure {
        require(a.toSlice().gte(b.toSlice()), "a not greater than or equal to b");
    }

    function callAssertContains(string memory a, string memory b) external pure {
        require(a.toSlice().contains(b.toSlice()), "a does not contain b");
    }
}

// StrSlice just wraps Slice's comparators, so these tests don't fuzz
// TODO currently invalid UTF-8 compares like bytes, but should it revert?
contract StrSliceAssertionsTest is PRBTest, StrSliceAssertions {
    StrSliceAssertionsRevertHelper helper;

    function setUp() public {
        helper = new StrSliceAssertionsRevertHelper();
    }
    /*//////////////////////////////////////////////////////////////////////////
                                        EQUALITY
    //////////////////////////////////////////////////////////////////////////*/

    function testEq() public {
        string memory b = unicode"こんにちは";
        // compare new assertions
        assertEq(b.toSlice(), b.toSlice());
        assertEq(b.toSlice(), b);
        assertEq(b, b.toSlice());

        assertLte(b.toSlice(), b.toSlice());
        assertLte(b.toSlice(), b);
        assertLte(b, b.toSlice());

        assertGte(b.toSlice(), b.toSlice());
        assertGte(b.toSlice(), b);
        assertGte(b, b.toSlice());
        // to the existing ones
        assertEq(b.toSlice().toString(), b.toSlice().toString());
        assertEq(b.toSlice().toString(), b);
        assertEq(b, b.toSlice().toString());
    }

    function test_Revert_Eq() public {
        vm.expectRevert();
        helper.callAssertEq(unicode"こん", unicode"こ");
    }

    function testNotEq() public {
        string memory b1 = unicode"こ";
        string memory b2 = unicode"ん";
        // compare new assertions
        assertNotEq(b1.toSlice(), b2.toSlice());
        assertNotEq(b1.toSlice(), b2);
        assertNotEq(b1, b2.toSlice());
        // to the existing ones
        assertNotEq(b1.toSlice().toString(), b2.toSlice().toString());
        assertNotEq(b1.toSlice().toString(), b2);
        assertNotEq(b1, b2.toSlice().toString());
    }

    function test_Revert_NotEq() public {
        vm.expectRevert();
        helper.callAssertNotEq(unicode"こんにちは", unicode"こんにちは");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    LESS-THAN
    //////////////////////////////////////////////////////////////////////////*/

    function testLt() public {
        string memory b1 = unicode"こ";
        string memory b2 = unicode"ん";

        assertLt(b1.toSlice(), b2.toSlice());
        assertLt(b1.toSlice(), b2);
        assertLt(b1, b2.toSlice());
        assertLt(b1, b2);

        assertLte(b1.toSlice(), b2.toSlice());
        assertLte(b1.toSlice(), b2);
        assertLte(b1, b2.toSlice());
        assertLte(b1, b2);
    }

    function test_Revert_Lt() public {
        vm.expectRevert();
        helper.callAssertLt(unicode"ん", unicode"こ");
    }

    function test_Revert_Lt__ForEq() public {
        vm.expectRevert();
        helper.callAssertLt(unicode"こ", unicode"こ");
    }

    function test_Revert_Lte() public {
        vm.expectRevert();
        helper.callAssertLte(unicode"ん", unicode"こ");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GREATER-THAN
    //////////////////////////////////////////////////////////////////////////*/

    function testGt() public {
        string memory b1 = unicode"ん";
        string memory b2 = unicode"こ";

        assertGt(b1.toSlice(), b2.toSlice());
        assertGt(b1.toSlice(), b2);
        assertGt(b1, b2.toSlice());
        assertGt(b1, b2);

        assertGte(b1.toSlice(), b2.toSlice());
        assertGte(b1.toSlice(), b2);
        assertGte(b1, b2.toSlice());
        assertGte(b1, b2);
    }

    function test_Revert_Gt() public {
        vm.expectRevert();
        helper.callAssertGt(unicode"こ", unicode"ん");
    }

    function test_Revert_Gt__ForEq() public {
        vm.expectRevert();
        helper.callAssertGt(unicode"こ", unicode"こ");
    }

    function test_Revert_Gte() public {
        vm.expectRevert();
        helper.callAssertGte(unicode"こ", unicode"ん");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTAINS
    //////////////////////////////////////////////////////////////////////////*/

    function testContains() public {
        string memory b1 = unicode"こんにちは";
        string memory b2 = unicode"んにち";

        assertContains(b1.toSlice(), b2.toSlice());
        assertContains(b1.toSlice(), b2);
        assertContains(b1, b2.toSlice());
        assertContains(b1, b2);
    }

    function test_Revert_Contains() public {
        vm.expectRevert();
        helper.callAssertContains(unicode"こんにちは", unicode"ここ");
    }
}
