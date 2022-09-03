// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import "src/BENSYC.sol";
import "src/Resolver.sol";
import "src/Interface.sol";
import "src/XCCIP.sol";
import "test/GenAddr.sol";

contract BENSYCScript is Script {

    using GenAddr for address;

    function run() external {
        vm.startBroadcast();
        
        /// @dev : Generate contract address before deployment
        address deployer = address(msg.sender);
        address bensycAddr = deployer.genAddr(vm.getNonce(deployer) + 1);
        Resolver resolver = new Resolver(bensycAddr);
        BoredENSYachtClub _bensyc = new BoredENSYachtClub(address(resolver), 100); // change to 10K for mainnet

        /// @dev : Check if generated address matches deployed address
        require(address(_bensyc) == bensycAddr, "CRITICAL: ADDRESSES NOT MATCHING");

        /// @dev : Set Resolver and Controller to contract
        //iENS _ens = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        //bytes32 _domainHash = _bensyc.DomainHash();
        //_ens.setResolver(_domainHash, address(_bensyc));
        //_ens.setApprovalForAll(address(_bensyc), true);

        /// @dev : CCIP Call
        XCCIP xccip = new XCCIP(address(_bensyc));

        vm.stopBroadcast();
        xccip;  //silence warning
    }
}
