// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import "src/BENSYC.sol";
import "src/Interface.sol";
import "src/XCCIP.sol";

contract BENSYCScript is Script {
    function run() external {
        vm.startBroadcast();
        BoredENSYachtClub _bensyc = new BoredENSYachtClub();
        XCCIP xccip = new XCCIP(address(_bensyc));
        xccip; //silence warning
        vm.stopBroadcast();
    }
}
