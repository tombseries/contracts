// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error NumberTooBig();

// Only includes information to encode a subset of roman numerals
library RomanNumeral {
    function ofNum(uint256 n) internal pure returns (string memory) {
        uint8[9] memory key = [100, 90, 50, 40, 10, 9, 5, 4, 1];
        string[9] memory numerals = ["C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        if (n >= 400) revert NumberTooBig();
        bytes memory res = "";
        for (uint256 i = 0; i < key.length; i++) {
            while (n >= key[i]) {
                n -= key[i];
                res = abi.encodePacked(res, numerals[i]);
            }
        }
        return string(res);
    }
}
