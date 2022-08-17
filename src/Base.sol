//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

//import "src/BENSYC.sol";
import "src/Interface.sol";
/**
 * @title contract
 */
abstract contract BENSYC {

    /// TESTNET ONLY : Remove for Mainnet
    function DESTROY() external payable onlyDev {
        selfdestruct(payable(msg.sender));
    }

    /// @dev : ENS Contract Interface
    iENS public ENS;

    /// @dev Pause / Resume contract 
    bool public active = true;

    /// @dev : DEV address 
    address public Dev;

    /// @dev : Modifier to alow only dev
    modifier onlyDev() {
        if(msg.sender != Dev)
            revert OnlyDev(Dev, msg.sender);

        _;
    }


    // NFT Details
    string internal _name = "BoredENSYachtClub.eth";
    string public symbol = "BENSYC";

    // @dev : Default resolver used by this contract
    address public DefaultResolver;

    /// @dev : Curent Total Supply of NFT
    uint256 public totalSupply;

    /// @dev : ERC20 token price to buy 1 NFT
    uint256 public mintingPrice;

    //Metadata public metadata; // metadata generator contract

    /// @dev : Opensea Contract URI
    string public contractURI = "ipfs://QmVYtPt9LG2wjzAsosKt5c5182tmqwVfc3vNJ1thpNQJR9"; // opensea contract uri hash

    /// @dev : ERC2981 Royalty info, 3 = 3%
    uint256 public royalty = 3;
    
    /// @dev : IPFS hash of metadata directory
    string public NFTData = "QmUVGA9sg2JRsR184Qj6EVCnZTEga9tDSdZ5ZQy1dZmkAs";

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

    error NotAuthorized(address operator, address owner, uint256 id);
    error NotOwner(address owner, address from, uint256 id);
    error NotEnough(uint256 size, uint256 yourSize);
    error ERC721IncompatibleReceiver(address addr);
    error OnlyDev(address _dev, address _you);
    error InvalidTokenID(uint256 id);
    error NotSubdomainOwner();
    error ContractPaused();
    error TransferToSelf();
    error TheEndOfMint();
    error ZeroAddress();
    error NotAllowed();

    modifier isValidToken(uint id) {
        if (id >= totalSupply)
            revert InvalidTokenID(id);

        _;
    }
    
    /**
     * @dev
     * @param sig :
     * @param value :
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev
     */
    function withdrawETH() external payable onlyDev {
        require(
            payable(msg.sender).send(address(this).balance)
            , "ETH_TRANSFER_FAILED"
        );
    }

    /**
     * @dev used in case some tokens are locked in this contract
     * @param token :
     */
    function withdrawToken(address token) external payable onlyDev {
        require(
            iERC20(token).transferFrom(address(this), Dev, iERC20(token).balanceOf(address(this)))
            , "TOKEN_TRANSFER_FAILED"
        );
    }
    
    fallback() external payable {
        revert NotAllowed();
    }

    receive() external payable {
        revert NotAllowed();
    }
}
