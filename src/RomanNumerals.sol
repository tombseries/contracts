// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error NumberTooBig();

// Only includes information to encode a subset of roman numerals
contract RomanNumeralSubset {
    
    uint[] key = [100, 90, 50, 40, 10, 9, 5, 4, 1];
    string[] numerals = ["C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
    
    function numeral(uint n) public view returns (string memory) {
        if (n >= 400) revert NumberTooBig();
        bytes memory res = "";
        for (uint i = 0; i < key.length; i++) {
            while (n >= key[i]) {
                n -= key[i];
                res = abi.encodePacked(res, numerals[i]);
            } 
        }
        return string(res);
    }
}