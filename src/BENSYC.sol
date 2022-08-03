//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >= 0.8 .0;

import "src/Interface.sol";
import "src/Metadata.sol";
//import "src/Resolver.sol";

/**
 * @summary:
 * @author:
 */

/**
 * @title contract
 */
abstract contract BENSYC {
    
    // 
    iENS public ENS;

    address public Dev; 

    bool public active = true;

    // NFT Details
    string public name = "BoredENSYachtClub.eth";
    string public symbol = "BENSYC";

    /// @dev : namehash of BoredENSYachtclub.eth
    bytes32 public DomainHash;

    /// @dev : namehash of bensyc.eth
    bytes32 public DomainHash2;

    /// @dev : Default resolver used by this contract
    address public DefaultResolver;

    /// @dev : Curent Total Supply of NFT
    uint256 public totalSupply;

    /// @dev : ERC20 Token used to buy NFT
    // iERC20 public ERC20;

    /// @dev : ERC20 token price to buy 1 NFT
    uint256 public mintingPrice;

    Metadata public metadata; // metadata generator contract

    /// @dev : Opensea Contract URI
    string public contractURI; // opensea contract uri hash

    /// @dev : ERC2981 Royalty info, 100 = 1%
    uint256 public royalty = 100;

    
    string public NFTData;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) internal _ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(bytes4 => bool) public supportsInterface;
    
    mapping(uint256 => bytes32) public ID2Labelhash;

    mapping(bytes32 => uint) public Hash2ID;
    //mapping(bytes32 => bytes32) public HashMap;

    event Transfer(address indexed src, address indexed dest, uint256 indexed id);
    event Approval(address indexed _owner, address indexed approved, uint256 indexed id);
    event ApprovalForAll(address indexed _owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error InvalidTokenID(uint256 id);
    error ERC721IncompatibleReceiver(address addr);
    error NotAuthorized(address operator, address owner, uint256 id);
    error NotOwner(address owner, address src, uint256 id);
    error ContractPaused();
    error TheEndOfMint();
    error LessThanMintingCost(uint256 value);
    error TransferToSelf();
    error NotSubdomainOwner();
    error ZeroAddress();
}

/**
 * @title contract
 */
contract BoredENSYachtClub is BENSYC {
    // @dev : Maximum supply of NFT
    uint256 public immutable maxSupply;

    /**
     * @dev
     * @param _metadata :
     * @param _resolver :
     */
    constructor(address _metadata, address _resolver, uint _maxSupply) {
        Dev = msg.sender;
        metadata = Metadata(_metadata);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        DefaultResolver = _resolver;
        maxSupply = _maxSupply;
        mintingPrice = 0.01 ether; //$ETH per NFT minting

        bytes32 _hash =
            keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        DomainHash = keccak256(
            abi.encodePacked(_hash, keccak256("boredensyachtclub"))
        );
        // EIP165
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
        supportsInterface[type(iERC2981).interfaceId] = true;
    }

    /**
     * @dev EIP721: returns owner of token ID
     * @param id : token id to check owner
     * @return : address of owner
     */
    function ownerOf(uint256 id) public view returns (address) {
        if (id >= totalSupply) {
            revert InvalidTokenID(id);
        }
        return _ownerOf[id];
    }

    /**
     * @dev EIP721: returns owner of token ID
     * @param id : token id to check owner
     * @return : address of owner
     */
    function ID2Namehash(uint256 id) public view returns (bytes32) {
        if (id >= totalSupply) {
            revert InvalidTokenID(id);
        }
        return keccak256(abi.encodePacked(DomainHash, ID2Labelhash[id]));
    }

    /**
     * @dev Mint function for single NFT, 
     */
    function mint() external payable {
        if (!active) {
            revert ContractPaused();
        }
        if (totalSupply > maxSupply) {
            revert TheEndOfMint();
        }
        if (msg.value < mintingPrice) {
            revert LessThanMintingCost(msg.value);
        }

        uint256 _id = totalSupply;
        bytes32 _labelhash = keccak256(abi.encodePacked(toString(_id)));
        ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, address(DefaultResolver), 0);
        ID2Labelhash[_id] = _labelhash;
        unchecked {
            ++totalSupply;
            ++balanceOf[msg.sender];
        }
        _ownerOf[_id] = msg.sender;
        emit Transfer(address(0), msg.sender, _id);
    }

    /**
     * @dev
     */
    function batchMint(uint256 num) external payable {
        if (!active) {
            revert ContractPaused();
        }
        if (msg.value < mintingPrice * num) {
            revert LessThanMintingCost(msg.value);
        }
        uint256 _id = totalSupply;
        uint256 _mint = _id + num;
        if (_mint > maxSupply) {
            revert TheEndOfMint();
        }
        for (; _id < _mint; _id++) {
            bytes32 _labelhash = keccak256(abi.encodePacked(toString(_id)));
            ENS.setSubnodeRecord(
                DomainHash, _labelhash, msg.sender, address(DefaultResolver), 0
            );
            ID2Labelhash[_id] = _labelhash;
            _ownerOf[_id] = msg.sender;
            emit Transfer(address(0), msg.sender, _id);
        }
        unchecked {
            totalSupply = _mint;
            balanceOf[msg.sender] += num;
        }
    }

    /**
     * @dev
     * @param src :
     * @param dest :
     * @param id :
     */
    function _transfer(address src, address dest, uint256 id, bytes memory data) private {
        if (!active) {
            revert ContractPaused();
        }
        if (dest == address(0)){
            revert ZeroAddress();
        }
        if (_ownerOf[id] != src) {
            revert NotOwner(_ownerOf[id], src, id);
        }
        if (
            msg.sender != _ownerOf[id] 
            && !isApprovedForAll[src][msg.sender] 
            && msg.sender != getApproved[id]
        ) {
            revert NotAuthorized(msg.sender, src, id);
        }
        // hard reset sub.domain ownership, users should change DefaultResolver/records
        ENS.setSubnodeOwner(DomainHash, ID2Labelhash[id], dest);
        unchecked {
            --balanceOf[src]; // subtract src owner
            ++balanceOf[dest]; // add to receiver
        }
        _ownerOf[id] = dest; // change ownership
        delete getApproved[id]; // reset approved
        if (dest.code.length > 0) {
            try iERC721Receiver(dest).onERC721Received(msg.sender, src, id, data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector){
                    revert ERC721IncompatibleReceiver(dest);
                }
            } catch {
                revert ERC721IncompatibleReceiver(dest);
            }
        }
        emit Transfer(src, dest, id);
    }

    //error ERC721IncompatibleReceiver(address to);
    /**
     * @dev
     * @param src :
     * @param dest :
     * @param id :
     */
    function transferFrom(address src, address dest, uint256 id)
        external
        payable
    {
        _transfer(src, dest, id, "");
    }

    /**
     * @dev
     * @param src :
     * @param dest :
     * @param id :
     */
    function safeTransferFrom(
        address src,
        address dest,
        uint256 id,
        bytes memory data
    )
        external
        payable
    {
        _transfer(src, dest, id, data);
    }

    /**
     * @dev
     * @param src :
     * @param dest :
     * @param id :
     */
    function safeTransferFrom(address src, address dest, uint256 id) external payable {
        _transfer(src, dest, id, "");
    }

    /**
     * @dev
     * @param approved :
     * @param id :
     */
    function approve(address approved, uint256 id) external payable {
        if(msg.sender != _ownerOf[id]){
            revert NotAuthorized(msg.sender, _ownerOf[id], id);
        }
        getApproved[id] = approved;
        emit Approval(msg.sender, approved, id);
    }

    /**
     * @dev
     * @param operator :
     * @param approved :
     */
    function setApprovalForAll(address operator, bool approved) external payable {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev
     * @param id :
     * @return : 
     */
    function tokenURI(uint256 id) external view returns (string memory) {
        if (id >= totalSupply) {
            revert InvalidTokenID(id);
        }
        if (bytes(NFTData).length > 0){
            return string.concat("ipfs://", NFTData, "/", toString(id), ".json");
        }
        return metadata.generate(id);
    }

    /**
     * @dev
     * @param id :
     * @param _salePrice :
     * @return :
     */
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        id; // silence warning
        return (Dev, _salePrice / royalty);
    }

    /**
    // Test function, if ownership of sub.domain was changed on ENS contract
    // new sub.domain owner can reclaim wrapped NFT? 
    function reclaim(uint256 id) external {
        if (!active) {
            revert ContractPaused();
        }
        if (id >= totalSupply) {
            revert InvalidTokenID(id);
        }
        address dest = msg.sender;
        if (ENS.owner(ID2Namehash[id]) != dest) {
            revert NotSubdomainOwner();
        }

        address src = _ownerOf[id];
        if (src == dest) {
            revert TransferToSelf();
        }
        unchecked {
            --balanceOf[src];
            ++(balanceOf[dest]);
        }
        delete getApproved[id]; // reset approved
        _ownerOf[id] = dest;
        emit Transfer(src, dest, id);
        if (dest.code.length > 0) {            
            try iERC721Receiver(dest).onERC721Received(msg.sender, src, id, "") returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector){
                    revert ERC721IncompatibleReceiver(dest);
                }
            } catch {
                revert ERC721IncompatibleReceiver(dest);
            }
        }
    }
     */

    // Contract Management
    modifier onlyDev() {
        require(msg.sender == Dev);
        _;
    }

    /**
     * @dev
     * @param newDev :
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev
     * @return : address of controlling dev/multisig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev Toggle if contract is active or paused, only Dev can toggle
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev
     * @param _resolver :
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        DefaultResolver = _resolver;
    }

    /**
     * @dev
     * @param _metadata :
     */
    function setMetadataContract(address _metadata) external onlyDev {
        metadata = Metadata(_metadata);
    }

    // used my opensea
    /**
     * @dev
     * @param _contractURI :
     */
    function setContractURI(string calldata _contractURI) external onlyDev {
        contractURI = _contractURI;
    }

    // EIP2981 royalty standard, percent * 100 units
    /**
     * @dev
     * @param _royalty :
     */
    function setRoyalty(uint256 _royalty) external onlyDev {
        royalty = _royalty;
    }

    /**
     * @dev
     */
    function withdraw() external payable onlyDev {
        require(
            payable(msg.sender).send(address(this).balance), "ETH_TRANSFER_FAILED"
        );
    }

    // in case erc20 token is locked/royalty
    /**
     * @dev used in case some tokens are locked in this contract
     * @param token :
     * @param value :
     */
    function withdraw(address token, uint256 value) external payable onlyDev {
        //require(
        iERC20(token).transferFrom(address(this), Dev, value);
        //, "TOKEN_TRANSFER_FAILED");
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

    // utility functions
    /**
     * @dev Convert uint value to string number
     * @param value : uint value to be converted
     * @return : number as string
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev
     * @param buffer : bytes to be converted to hex
     * @return : hex string
     */
    function toHexString(bytes memory buffer)
        internal
        pure
        returns (string memory)
    {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint256 i; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / 16];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % 16];
        }
        return string(abi.encodePacked("0x", converted));
    }

    function DESTROY() public {
        require(msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }
}