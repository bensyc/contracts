//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >= 0.8 .15;

import "src/Interface.sol";
import "src/Metadata.sol";
import "src/Resolver.sol";

/**
 * @summary: 
 * @author: 
 */


/**
 * @title contract 
 */
abstract contract BENSYC {

    iENS public ENS;
    address public Dev; //multisig

    bool public active = true;

    // NFT Details
    string public name = "BoredENSYachtClub.eth";
    string public symbol = "BENSYC";

    /// @dev : namehash of BoredENSYachtclub.eth
    bytes32 public DomainHash;

    /// @dev : Default resolver used by this contract
    address public DefaultResolver;

    /// @dev : Curent Total Supply of NFT
    uint public totalSupply;

    // @dev : Maximum supply of NFT
    uint public immutable maxSupply = 100;

    /// @dev : ERC20 Token used to buy NFT
    // iERC20 public ERC20;

    /// @dev : ERC20 token price to buy 1 NFT
    uint public mintingPrice;

    Metadata public metadata; // metadata generator contract

    /// @dev : Opensea Contract URI 
    string public contractURI; // opensea contract uri hash

    /// @dev : ERC2981 Royalty info, 100 = 1%
    uint public royalty = 100;

    mapping(address => uint) public balanceOf;
    mapping(uint => address) public _ownerOf;
    mapping(uint => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(bytes4 => bool) public supportsInterface;

    mapping(uint => bytes32) public ID2Namehash;
    mapping(uint => bytes32) public ID2Labelhash;

    //mapping(bytes32 => uint) public Hash2ID;

    event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    error InvalidTokenID(uint id);
    error ERC721IncompatibleReceiver(address addr);
    error NotAuthorized(address operator, address owner, uint id);
    error NotOwner(address owner, address from, uint id);
    error ContractPaused();
    error MintingCompleted();
    error NotEnoughPaid(uint value);
    error TransferToSelf();
    error NotSubdomainOwner();
}

/**
 * @title contract 
 */
contract BoredENSYachtClub is BENSYC {


    /**
     * @dev
     * @param _metadata :
     * @param _resolver :
     */
    constructor(address _metadata, address _resolver) {

        Dev = msg.sender;
        metadata = Metadata(_metadata);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        DefaultResolver = _resolver;

        //ERC20 = iERC20(_token); // token used for NFT minting
        mintingPrice = 0.01 ether; // tokens per NFT minting

        bytes32 _hash = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        DomainHash = keccak256(abi.encodePacked(_hash, keccak256(abi.encodePacked("boredensyachtclub"))));

        //metadata = "ipfs://<hash of .json dir>"; // ipfs://<hash>
        //contractURI = "";


        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

        // EIP165
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
        supportsInterface[type(iERC2981).interfaceId] = true;
    }

    /**
     * @dev
     * @param _tokenId :
     * @return :
     */
    function ownerOf(uint _tokenId) public view returns(address) {
        if(_tokenId >= totalSupply) {
            revert InvalidTokenID(_tokenId);
        }
        address _owner = ENS.owner(ID2Namehash[_tokenId]);
        if(_owner == _ownerOf[_tokenId]) {
            return _owner;
        }
        return address(this);
    }

    /**
     * @dev
     */
    function mint() external payable {
        if(!active) {
            revert ContractPaused();
        }
        if(totalSupply > maxSupply) {
            revert MintingCompleted();
        }
        if(msg.value < mintingPrice) {
            revert NotEnoughPaid(msg.value);
        }

        //transfer erc20 token 
        //require(ERC20.transferFrom(msg.sender, address(Dev), mintingPrice), "ERC20:TOKEN_TRANSFER_FAILED");

        uint _id = totalSupply;
        bytes32 _labelhash = keccak256(abi.encodePacked(toString(_id)));
        ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, address(DefaultResolver), 0);
        bytes32 _namehash = keccak256(abi.encodePacked(DomainHash, _labelhash));
        ID2Namehash[_id] = _namehash;
        ID2Labelhash[_id] = _labelhash;
        //Hash2ID[_labelhash] = _id;
        //Hash2ID[_namehash] = _id;
        unchecked {
            ++totalSupply;
            ++balanceOf[msg.sender];
        }
        _ownerOf[_id] = msg.sender;
        //emit Transfer(address(0), address(this), _id);
        emit Transfer(address(this), msg.sender, _id);
    }


    /**
     * @dev
     */
    function batchMint(uint num) external payable {
        if(!active) {
            revert ContractPaused();
        }
        if(totalSupply + num > maxSupply) {
            revert MintingCompleted();
        }
        if(msg.value < mintingPrice * num) {
            revert NotEnoughPaid(msg.value);
        }
        uint _id = totalSupply;
        uint _mint = _id + num;
        for(; _id < _mint; _id++){
            bytes32 _labelhash = keccak256(abi.encodePacked(toString(_id)));
            ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, address(DefaultResolver), 0);
            ID2Namehash[_id] = keccak256(abi.encodePacked(DomainHash, _labelhash));
            ID2Labelhash[_id] = _labelhash;
            _ownerOf[_id] = msg.sender;
            emit Transfer(address(this), msg.sender, _id);
        }
        unchecked {
            totalSupply = _mint;
            balanceOf[msg.sender] += num;
        }
    }

    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function _transfer(address _from, address _to, uint _tokenId, bytes memory _data) private {
        if(!active) {
            revert ContractPaused();
        }
        //require(_to != address(0), "ERC721:ZERO_ADDRESS");
        if(_ownerOf[_tokenId] != _from){
            revert NotOwner(_ownerOf[_tokenId], _from, _tokenId);
        }
        //require(ENS.owner(ID2Namehash[_tokenId]) == _from, "ERC721:ENS_OWNER_MISMATCH");
        if(msg.sender != _ownerOf[_tokenId] &&
            !isApprovedForAll[_from][msg.sender] &&
            msg.sender != getApproved[_tokenId]) {
            revert NotAuthorized(msg.sender, _from, _tokenId);
        }
        // hard reset sub.domain ownership, users should change DefaultResolver/records
        ENS.setSubnodeOwner(DomainHash, ID2Labelhash[_tokenId], _to);
        unchecked {
            --balanceOf[_from]; // subtract from owner
            ++balanceOf[_to]; // add to receiver
        }
        _ownerOf[_tokenId] = _to; // change ownership
        delete getApproved[_tokenId]; // reset approved
        if(_to.code.length > 0){
            try iERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector){
                    revert ERC721IncompatibleReceiver(_to);
                }
            } catch (bytes memory) {
                revert ERC721IncompatibleReceiver(_to);
            }
        }
        emit Transfer(_from, _to, _tokenId);
    }
    //error ERC721ReceiverRejected(address to);
    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function transferFrom(address _from, address _to, uint _tokenId) external payable {
        _transfer(_from, _to, _tokenId, "");
    }

    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory _data) external payable {
        _transfer(_from, _to, _tokenId, _data);
    }

    /**
     * @dev
     * @param _from :
     * @param _to :
     * @param _tokenId :
     */
    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable {
        _transfer(_from, _to, _tokenId, "");
    }

    /**
     * @dev
     * @param _manager :
     * @param _tokenId :
     */
    function approve(address _manager, uint _tokenId) external payable {
        require(msg.sender == ownerOf(_tokenId), "ERC721:NOT_OWNER");
        getApproved[_tokenId] = _manager;
        emit Approval(msg.sender, _manager, _tokenId);
    }

    /**
     * @dev
     * @param _operator :
     * @param _approved :
     */
    function setApprovalForAll(address _operator, bool _approved) external payable {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev
     * @param _tokenId :
     * @return :
     */
    function tokenURI(uint _tokenId) external view returns(string memory) {
        if(_tokenId >= totalSupply) {
            revert InvalidTokenID(_tokenId);
        }
        return metadata.generate(_tokenId);
    }

    /**
     * @dev
     * @param _tokenId :
     * @param _salePrice :
     * @return :
     */
    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns(address, uint) {
        _tokenId; // silence warning
        return (address(this), (_salePrice / royalty));
    }

    // extra function, if ownership of sub.domain was changed on ENS contract
    // new sub.domain owner can reclaim wrapped NFT
    /**
     * @dev
     * @param _tokenId :
     */
    function reclaim(uint _tokenId) external {
        if(_tokenId >= totalSupply) {
            revert InvalidTokenID(_tokenId);
        }
        address _to = msg.sender;
        if(ENS.owner(ID2Namehash[_tokenId]) != _to) {
            revert NotSubdomainOwner();
        }

        address _from = _ownerOf[_tokenId];
        if(_from == _to) {
            revert TransferToSelf();
        }
        unchecked {
            --balanceOf[_from];
            ++balanceOf[_to];
        }
        delete getApproved[_tokenId]; // reset approved
        _ownerOf[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        if(_to.code.length > 0 &&
            iERC721Receiver(_to).onERC721Received(_to, _from, _tokenId, "") !=
            iERC721Receiver.onERC721Received.selector) {
            revert ERC721IncompatibleReceiver(_to);
        }
    }

    // Contract Management
    modifier onlyDev {
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
    function owner() external view returns(address) {
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
    function setResolver(address _resolver) external onlyDev {
        DefaultResolver = _resolver;
    }
    
    /**
     * @dev
     * @param _metadata :
     */
    function setMetadata(address _metadata) external onlyDev {
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
    function setRoyalty(uint _royalty) external onlyDev {
        royalty = _royalty;
    }

    /**
     * @dev
     */
    function withdraw() external payable onlyDev {
        require(payable(msg.sender).send(address(this).balance), "ETH_TRANSFER_FAILED");
    }

    // in case erc20 token is locked/royalty
    /**
     * @dev used in case some tokens are locked in this contract
     * @param _token : 
     * @param _value :
     */
    function approveToken(address _token, uint _value) external payable onlyDev {
        iERC721(_token).approve(msg.sender, _value);
    }

    /**
     * @dev
     * @param _sig :
     * @param _ok:
     */
    function setInterface(bytes4 _sig, bool _ok) external payable onlyDev {
        require(_sig != 0xffffffff);
        supportsInterface[_sig] = _ok;
    }

    // utility functions
    /**
     * @dev Convert uint value to string number
     * @param value : uint value to be converted
     * @return : number as string
     */
    function toString(uint value) internal pure returns(string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if(value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev
     * @param buffer : bytes to be converted to hex
     * @return : hex string 
     */
    function toHexString(bytes memory buffer) internal pure returns(string memory) {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint i; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / 16];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % 16];
        }
        return string(abi.encodePacked("0x", converted));
    }

    function DESTROY() public {
        require (msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }
}