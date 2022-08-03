// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import "src/BENSYC.sol";
import "src/Metadata.sol";
import "src/Resolver.sol";
import "src/XCCIP.sol";
import "test/Create1.sol";
contract BENSYCScript is Script {
    using Create1 for address;
    function run() external {
        vm.startBroadcast();
        Metadata metadata = new Metadata();
        address bensycAddr = address(0x25614B96A0A0Df3B05402089a00f0E5B5563a120).create1(vm.getNonce(address(0x25614B96A0A0Df3B05402089a00f0E5B5563a120))+1);
        Resolver resolver = new Resolver(bensycAddr);
        BoredENSYachtClub bensyc = new BoredENSYachtClub(address(metadata), address(resolver), 1e4);
        require(address(bensyc) == bensycAddr, "TEST: ADDRESS NOT MATCHING");
        XCCIP xccip = new XCCIP(bensycAddr);
        vm.stopBroadcast();
    }
}
