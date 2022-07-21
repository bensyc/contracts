// SPDX-License-Identifier: WTFPL v6.9
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/BENSYC.sol";
import "src/Metadata.sol";
import "src/Resolver.sol";

contract NotReceiver721{
    address _a = address(0xc0de4c0ffee);
}
contract BENSYCTest is Test {
    using stdStorage for StdStorage;

    function setUp() public {
        address _addr = _ens.owner(_bensyc.DomainHash());
        require(_addr != address(0), "ZERO");
        //console.log("1ADDR:", _addr);
        vm.prank(_addr);
        _ens.setApprovalForAll(address(_bensyc), true);
        //_token.approve(address(_bensyc), type(uint).max);  
    }

    BoredENSYachtClub public _bensyc;
    Metadata public _metadata;
    Resolver public _resolver;
    uint public mintingPrice; 
    iENS public _ens = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    NotReceiver721 public _notReceiver;
    constructor(){
        _metadata = new Metadata();
        _resolver = new Resolver();
        _bensyc = new BoredENSYachtClub(address(_metadata), address(_resolver));
        _notReceiver = new NotReceiver721();
        mintingPrice = _bensyc.mintingPrice();
    }

    function testCheckNameSymbol() public {
        assertEq(_bensyc.name(), "BoredENSYachtClub.eth");
        assertEq(_bensyc.symbol(), "BENSYC");
        //console.log(bytes(_bensyc.DomainHash()));
    }

    function testSupplyzero() public{
        assertEq(_bensyc.totalSupply(), 0);
    }

    function testcheckSetApproval() public {
        address _addr = _ens.owner(_bensyc.DomainHash());
        assertTrue(_ens.isApprovedForAll(_addr, address(_bensyc)));
    }  
    
    function testSubMinting() public{        
        _bensyc.mint{value:mintingPrice}();
        assertEq(_bensyc.ownerOf(0), address(this));
        assertEq(_bensyc.balanceOf(address(this)), 1);
        assertEq(_ens.owner(_bensyc.ID2Namehash(0)), address(this));
        assertEq(_ens.resolver(_bensyc.ID2Namehash(0)),(_bensyc.DefaultResolver()));
    }

    function testMintingSolo100() public{
        for (uint i = 0; i < 100; i++) {
            _bensyc.mint{value:0.1 ether}();
            assertEq(_bensyc.ownerOf(i), address(this));
            assertEq(_ens.owner(_bensyc.ID2Namehash(i)), address(this));
            assertEq(_ens.resolver(_bensyc.ID2Namehash(i)), _bensyc.DefaultResolver());
        }
    }
    function testBatchMinting10() public{
        _bensyc.batchMint{value:0.1 ether}(10);
        for (uint i = 0; i < 10; i++) {
            assertEq(_bensyc.ownerOf(i), address(this));
            assertEq(_ens.owner(_bensyc.ID2Namehash(i)), address(this));
            assertEq(_ens.resolver(_bensyc.ID2Namehash(i)), _bensyc.DefaultResolver());
        }
    }
    function testBatchMinting100() public{
        for (uint i = 0; i < 10; i++) {
            _bensyc.batchMint{value:0.1 ether}(10);
        }
        for (uint j = 0; j < 100; j++) {
            assertEq(_bensyc.ownerOf(j), address(this));
            assertEq(_ens.owner(_bensyc.ID2Namehash(j)), address(this));
            assertEq(_ens.resolver(_bensyc.ID2Namehash(j)), _bensyc.DefaultResolver());
            j *= 3;
        }
        console.log(_bensyc.totalSupply());
    }

    function testTransfer() public{
        _bensyc.mint{value:mintingPrice}();
        address _addr = _bensyc.ownerOf(0);
        console.log("Domain Owner A:", _addr);
        _bensyc.transferFrom(_addr, address(0xc0de4c0ffee), 0);
        _addr = _bensyc.ownerOf(0);
        console.log("Domain Owner B :", _addr);
        assertEq(_addr, address(0xc0de4c0ffee));
    }
    function testCannotTransfer() public{
        _bensyc.mint{value:mintingPrice}();
        vm.expectRevert(abi.encodeWithSelector(BENSYC.NotOwner.selector, address(this), address(0xc0de4c0ffee), 0));
        _bensyc.transferFrom(address(0xc0de4c0ffee), address(0xc0de4c0ffee), 0);
    }
    
    function testCannotReceiveContract() public {
        _bensyc.mint{value:mintingPrice}();
        address _from = _bensyc.ownerOf(0);
        console.log(address(_notReceiver).code.length);
        vm.expectRevert(abi.encodeWithSelector(BENSYC.ERC721IncompatibleReceiver.selector, address(_notReceiver)));
        _bensyc.transferFrom(_from, address(_notReceiver), 0);
    }
    address notPure;     
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes memory _data) external returns(bytes4){
        notPure = _operator;
        _from;
        _tokenId;
        _data;
        return BENSYCTest.onERC721Received.selector;
    }
}