// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../RomanNumerals.sol";

contract RomanNumeralSubsetTest is DSTest {
    RomanNumeralSubset internal Contract;

    function setUp() public {
        Contract = new RomanNumeralSubset();
    }

    function testNumbers() public {
        assertEq(Contract.numeral(1), "I");
        assertEq(Contract.numeral(117), "CXVII");
        assertEq(Contract.numeral(177), "CLXXVII");
    }

    function testSingleNumber() public {
        assertEq(Contract.numeral(177), "CLXXVII");
    }

    function testFailNumberTooBig() view public{
        Contract.numeral(400);
    }
}
