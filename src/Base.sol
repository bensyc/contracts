//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";

/**
 * @title BENSYC Definitions
 */
abstract contract BENSYC {

    // TESTNET ONLY : REMOVE FROM MAINNET !!!
    function DESTROY() external payable onlyDev {
        selfdestruct(payable(msg.sender));
    }

    /// @dev : ENS Contract Interface
    iENS public ENS;

    /// @dev Pause/Resume contract 
    bool public active = true;

    /// @dev : Controller/Dev address 
    address public Dev;

    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if(msg.sender != Dev)
            revert OnlyDev(Dev, msg.sender);
        _;
    }


    // ERC721 details
    string internal _name = "BoredENSYachtClub.eth";
    string public symbol = "BENSYC";

    /// @dev : Default resolver used by this contract: NEEDS TO BE SET FOR MAINNET !!!
    address public DefaultResolver;

    /// @dev : Current/Live supply of subdomains
    uint256 public totalSupply;

    /// @dev : $ETH per subdomain mint
    uint256 public mintPrice = 0.01 ether;

    /// @dev : Opensea Contract URI
    string public contractURI = "ipfs://QmVYtPt9LG2wjzAsosKt5c5182tmqwVfc3vNJ1thpNQJR9"; // opensea contract uri hash

    /// @dev : ERC2981 Royalty info; 5 = 5%
    uint256 public royalty = 5;
    
    /// @dev : IPFS hash of metadata directory
    string public metaIPFS = "Qmeeseyvfcx3Ur65y7awVRywwAvBRBDSdsX2GKgyUxgnJP";


    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) internal _ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(bytes4 => bool) public supportsInterface;
    mapping(uint256 => bytes32) public ID2Labelhash;
    mapping(bytes32 => uint) public Namehash2ID;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed _owner, address indexed approved, uint256 indexed id);
    event ApprovalForAll(address indexed _owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error Unauthorized(address operator, address owner, uint256 id);
    error NotSubdomainOwner(address owner, address from, uint256 id);
    error InsufficientEtherSent(uint256 size, uint256 yourSize);
    error ERC721IncompatibleReceiver(address addr);
    error OnlyDev(address _dev, address _you);
    error InvalidTokenID(uint256 id);
    error ContractPaused();
    error MintEnded();
    error ZeroAddress();
    error OversizedBatch();

    modifier isValidToken(uint id) {
        if (id >= totalSupply)
            revert InvalidTokenID(id);
        _;
    }
    
    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external payable onlyDev {
        require(
            payable(msg.sender).send(address(this).balance)
            , "ETH_TRANSFER_FAILED"
        );
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     */
    function withdrawToken(address token) external payable onlyDev {
        require(
            iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)))
            , "TOKEN_TRANSFER_FAILED"
        );
    }
    
    // @dev : re-entrancy protectoooor
    fallback() external payable {
        revert();
    }
    receive() external payable {
        revert();
    }
}
