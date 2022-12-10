// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../ShadowDistribution.sol";

contract SaveRanking is Script {
    function run() external {
        uint256[] memory ids = new uint256[](36);
        address[] memory addrs = new address[](36);

        for (uint256 i = 0; i < 36; i++) {
            ids[i] = i + 1;
        }

        addrs[0] = 0x1483a878832Ac0BD00F635E3615af9937fde258d;
        addrs[1] = 0x9303EA8dDAf762a3a1F9A8C82c4F16FB70733aC3;
        addrs[2] = 0x4b10DA491b54ffe167Ec5AAf7046804fADA027d2;
        addrs[3] = 0x518201899E316bf98c957C73e1326b77672Fe52b;
        addrs[4] = 0x76a7bD1B8527662BcDbE2981049D052eD3b6DDC5;
        addrs[5] = 0x625D6405DCac9C82F4b681A131d9182115448F75;
        addrs[6] = 0x63dC34b6A35C1DCA3de2460c15138d2Aa92C523a;
        addrs[7] = 0x113d754Ff2e6Ca9Fd6aB51932493E4F9DabdF596;
        addrs[8] = 0x67F3E43c779449be61580FC75a42D143e840f04c;
        addrs[9] = 0x834C69EF569F26815B5dCc87e24267346346CE08;
        addrs[10] = 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46;
        addrs[11] = 0xa0eb90B7AAC3f508aBC5e21D87dCa1c3f2129C77;
        addrs[12] = 0x912b37E4AD159882f60De59B27882c5daf3d7E5B;
        addrs[13] = 0xC4cd14A15a94Be727af253335abAFD6b6F411aCd;
        addrs[14] = 0x20b48BdF395232ACAe5D6E3b345c0f107FFA8AbD;
        addrs[15] = 0x8d138c01765483cB79d787ce5933F609CbFDabcF;
        addrs[16] = 0x6E56a3D5188EEde5984B4EE004795AC0aaB1cD4c;
        addrs[17] = 0xF930b0A0500D8F53b2E7EFa4F7bCB5cc0c71067E;
        addrs[18] = 0x6Af920b0D2Db08c2d1C7AC7EF841615cAeFFD025;
        addrs[19] = 0xC9C022FCFebE730710aE93CA9247c5Ec9d9236d0;
        addrs[20] = 0xCBBea7Ec33D60Db283AB79bdAC9ffbfa46A83134;
        addrs[21] = 0xaCAA5d549e2f18314C5424D2a94711034faa6F64;
        addrs[22] = 0xfB843f8c4992EfDb6b42349C35f025ca55742D33;
        addrs[23] = 0xF73FE15cFB88ea3C7f301F16adE3c02564ACa407;
        addrs[24] = 0xdA2ba9f10C336e76CD31b8A9005F05C7D560066a;
        addrs[25] = 0x3d9456Ad6463a77bD77123Cb4836e463030bfAb4;
        addrs[26] = 0x062E0B7846094C24848F9fa3dcD892515e9cA13F;
        addrs[27] = 0x666669651612b8b1Ce852012F3c00bD3038AF143;
        addrs[28] = 0xcADe1E68A994C5b1459cCD19150128Ffef09Ea3c;
        addrs[29] = 0x592d90c916D3082fF9640e99Fe2C8503948d1EBc;
        addrs[30] = 0xdBD6D78de900074Aac480b6AA56973CBE3cdd821;
        addrs[31] = 0xB00A93fF31217E49c3674e05b525f239a85bb78f;
        addrs[32] = 0x0885F0e1a641F08416536e3921C30c5D9dC9c0f4;
        addrs[33] = 0x7E5507281F62C0f8d666beAEA212751cD88994b8;
        addrs[34] = 0xDD94b65218366e60ddB45cf119D636426Fdec3Cf;
        addrs[35] = 0x6Be0b92D94F3bb772E2d76cc72C62B14895F32f3;

        vm.startBroadcast(0x9aaC8cCDf50dD34d06DF661602076a07750941F6);
        ShadowDistribution shadowDistribution = new ShadowDistribution(
            0xE877CDACBB7827d4232Cde5f8de58371F144a0A4,
            0xcC1775Ea6D7F62b4DCA8FAF075F864d3e15Dd0F0
        );
        shadowDistribution.saveMapping(ids, addrs);
        vm.stopBroadcast();
    }
}
