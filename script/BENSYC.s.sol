// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import "src/BENSYC.sol";
import "src/Interface.sol";
import "src/XCCIP.sol";
//import "test/Create1.sol";
contract BENSYCScript is Script {
    //using Create1 for address;
    function run() external {
        vm.startBroadcast();
        //address deployer = address(msg.sender);
        //address bensycAddr = deployer.create1(vm.getNonce(deployer)+1);
        //Resolver resolver = new Resolver(bensycAddr);
        BoredENSYachtClub _bensyc = new BoredENSYachtClub(100);
        //require(address(bensyc) == bensycAddr, "TEST: ADDRESS NOT MATCHING");
        //iENS _ens = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        //bytes32 _domainHash = _bensyc.DomainHash();
        //_ens.setResolver(_domainHash, address(_bensyc));
        //_ens.setApprovalForAll(address(_bensyc), true);
        XCCIP xccip = new XCCIP(address(_bensyc));
        vm.stopBroadcast();
    }
}
