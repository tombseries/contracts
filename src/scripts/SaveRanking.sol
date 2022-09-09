// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../ShadowDistribution.sol";

contract SaveRanking is Script {
  function run() external {
    ShadowDistribution shadowDistribution = ShadowDistribution(
      0xeC0a7349dC663a4C2363E72ee9de5aE24FA01163
    );

    uint256[] memory ids = new uint256[](36);
    address[] memory addrs = new address[](36);

    for (uint256 i = 0; i < 36; i++) {
      ids[i] = i + 1;
    }

    addrs[0] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[1] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[2] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[3] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[4] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[5] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[6] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[7] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[8] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[9] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[10] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[11] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[12] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[13] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[14] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[15] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[16] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[17] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
    addrs[18] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[19] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[20] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[21] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[22] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[23] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[24] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[25] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[26] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[27] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[28] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[29] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[30] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[31] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[32] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[33] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[34] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
    addrs[35] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;

    vm.startBroadcast(0x9aaC8cCDf50dD34d06DF661602076a07750941F6);
    shadowDistribution.saveMapping(ids, addrs);
    vm.stopBroadcast();
  }
}
