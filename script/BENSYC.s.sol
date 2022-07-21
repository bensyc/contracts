// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import "src/BENSYC.sol";
import "src/Metadata.sol";
import "src/Resolver.sol";
contract BENSYCScript is Script {
    function run() external {
        vm.startBroadcast();

        Metadata metadata = new Metadata();
        Resolver resolver = new Resolver();
        //0xe52a81cebb791e8e155494e5e5658b054677c79c 
        //metadata /svg generator 0x0b2656eb5205108e140c2855e2986e934df82a1c
        BoredENSYachtClub bensyc = new BoredENSYachtClub(address(metadata), address(resolver));

        vm.stopBroadcast();
    }
}
