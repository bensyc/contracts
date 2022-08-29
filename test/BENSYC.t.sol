// SPDX-License-Identifier: WTFPL v6.9
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/BENSYC.sol";
import "src/Resolver.sol";
import "src/XCCIP.sol";
import "test/GenAddr.sol";

// @dev : for testing
contract CannotReceive721 {
    address _a = address(0xc0de4c0cac01a);
}

// @dev : Tester
contract BENSYCTest is Test {
    using stdStorage for StdStorage;
    using GenAddr for address;

    /// @dev : set contract as controller for boredensyachtclub.eth
    function setUp() public {
        address _addr = ENS.owner(_bensyc.DomainHash());
        require(_addr != address(0), "Revert: 0 address detected");
        vm.prank(_addr);
        ENS.setApprovalForAll(address(_bensyc), true);
    }

    BoredENSYachtClub public _bensyc;
 
    XCCIP public _xccip;
    uint public mintPrice;
    iENS public ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    CannotReceive721 public _notReceiver;
    constructor() {
        _bensyc = new BoredENSYachtClub();
        _notReceiver = new CannotReceive721();
        mintPrice = _bensyc.mintPrice();
    }

    /// @dev : verify name & symbol
    function testCheckNameSymbol() public {
        assertEq(_bensyc.name(), "BoredENSYachtClub.eth");
        assertEq(_bensyc.symbol(), "BENSYC");
    }

    /// @dev : verify zero supply at start
    function testCheckZeroSupply() public {
        assertEq(_bensyc.totalSupply(), 0);
    }

    /// @dev : check if contract is authorised by boredensyachtclub.eth
    function testCheckContractIsController() public {
        address _addr = ENS.owner(_bensyc.DomainHash());
        assertTrue(ENS.isApprovedForAll(_addr, address(_bensyc)));
    }

    /// @dev : test minting one subdomain, verify ownership & resolver
    function testSubdomainMint() public {
        _bensyc.mint {
            value: mintPrice
        }();
        assertEq(_bensyc.ownerOf(0), address(this));
        assertEq(_bensyc.balanceOf(address(this)), 1);
        assertEq(ENS.owner(_bensyc.ID2Namehash(0)), address(this));
        assertEq(ENS.resolver(_bensyc.ID2Namehash(0)), address(_bensyc.DefaultResolver()));
    }

    /// @dev : test minting out the entire supply one by one
    function testMintTokensIndividually() public {
        uint maxSupply = 100;
        for (uint i = 0; i < maxSupply; i++) {
            _bensyc.mint {
                value: 0.01 ether
            }();
            assertEq(_bensyc.ownerOf(i), address(this));
            assertEq(ENS.owner(_bensyc.ID2Namehash(i)), address(this));
            assertEq(ENS.resolver(_bensyc.ID2Namehash(i)), address(_bensyc.DefaultResolver()));
        }
    }

    /// @dev : test minting a batch with size < 13
    function testBatchMint() public {
        uint batchSize = 8;
        _bensyc.batchMint {
            value: batchSize * 0.01 ether
        }(batchSize);
        for (uint i = 0; i < batchSize; i++) {
            assertEq(_bensyc.ownerOf(i), address(this));
            assertEq(ENS.owner(_bensyc.ID2Namehash(i)), address(this));
            assertEq(ENS.resolver(_bensyc.ID2Namehash(i)), address(_bensyc.DefaultResolver()));
        }
    }

    /// @dev : verify that batchMint() fails when batchSize > 12
    function testCannotMintOversizedBatch() public {
        uint batchSize = 13;
        vm.expectRevert(abi.encodeWithSelector(BENSYC.OversizedBatch.selector));
        _bensyc.batchMint {
            value: batchSize * 0.01 ether
        }(batchSize);
    }

    /// @dev : verify that owner can transfer subdomain
    function testSubdomainTransfer() public {
        _bensyc.mint {
            value: mintPrice
        }();
        address _addr = _bensyc.ownerOf(0);
        _bensyc.transferFrom(_addr, address(0xc0de4c0cac01a), 0);
        _addr = _bensyc.ownerOf(0);
        assertEq(_addr, address(0xc0de4c0cac01a));
    }

    /// @dev : verify that contract (= parent controller) cannot transfer a subdomain
    function testContractCannotTransfer() public {
        _bensyc.mint {
            value: mintPrice
        }();
        vm.expectRevert(abi.encodeWithSelector(BENSYC.NotSubdomainOwner.selector, address(this), address(0xc0de4c0cac01a), 0));
        _bensyc.transferFrom(address(0xc0de4c0cac01a), address(0xc0de4c0cac01a), 0);
    }

    /// @dev : verify that contract cannot receive a subdomain
    function testContractCannotReceive() public {
        _bensyc.mint {
            value: mintPrice
        }();
        address _from = _bensyc.ownerOf(0);
        vm.expectRevert(abi.encodeWithSelector(BENSYC.ERC721IncompatibleReceiver.selector, address(_notReceiver)));
        _bensyc.transferFrom(_from, address(_notReceiver), 0);
    }

    // @dev : generic onERC721Received tester
    address notPure;
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes memory _data) external returns(bytes4) {
        notPure = _operator;
        _from;
        _tokenId;
        _data;
        return BENSYCTest.onERC721Received.selector;
    }
}
