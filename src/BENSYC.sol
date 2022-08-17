//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";
import "src/Resolver.sol";
import "src/Util.sol";
import "src/Base.sol";

/**
 * @summary:
 * @author:
 */


/**
 * @title contract
 */
contract BoredENSYachtClub is BENSYC, Resolver {
    using Util for uint256;
    using Util for bytes;

    // @dev : Maximum supply of NFT
    uint256 public immutable maxSupply;

    /// @dev : namehash of boredensyacht.eth
    bytes32 public immutable DomainHash;
    
    /**
     * @dev
     * @param _resolver :
     */
    constructor(uint _maxSupply) {
        Dev = msg.sender;
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        DefaultResolver = address(this);
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
     * @dev EIP721: Token name
     * @return : String Name of Token
     */
    function name() external view returns(string memory){
        return _name;
    }
    /**
     * @dev EIP721: returns owner of token ID
     * @param id : token id to check owner
     * @return : address of owner
     */
    function ownerOf(uint256 id) public view isValidToken(id) returns (address) {
        return _ownerOf[id];
    }

    /**
     * @dev 
     * @param id : token id to check owner
     * @return : address of owner
     */
    function ID2Namehash(uint256 id) public view isValidToken(id) returns (bytes32) {
        return keccak256(abi.encodePacked(DomainHash, ID2Labelhash[id]));
    }

    /**
     * @dev Mint function for single NFT, 
     */
    function mint() external payable {
        if (!active)
            revert ContractPaused();

        if (totalSupply > maxSupply)
            revert TheEndOfMint();

        if (msg.value < mintingPrice)
            revert NotEnough(mintingPrice, msg.value);


        uint256 _id = totalSupply;
        bytes32 _labelhash = keccak256(abi.encodePacked(_id.toString()));
        ENS.setSubnodeRecord(
            DomainHash, _labelhash, msg.sender, DefaultResolver, 0
        );
        ID2Labelhash[_id] = _labelhash;
        Namehash2ID[keccak256(abi.encodePacked(DomainHash, _labelhash))] = _id;
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
        if (!active)
            revert ContractPaused();

        if (msg.value < mintingPrice * num)
            revert NotEnough(mintingPrice * num, msg.value);

        uint256 _id = totalSupply;
        uint256 _mint = _id + num;
        if (_mint > maxSupply)
            revert TheEndOfMint();
        bytes32 _labelhash;
        while (_id < _mint) {
            _labelhash = keccak256(abi.encodePacked(_id.toString()));
            ENS.setSubnodeRecord(
                DomainHash, _labelhash, msg.sender, DefaultResolver, 0
            );
            ID2Labelhash[_id] = _labelhash;
            Namehash2ID[keccak256(abi.encodePacked(DomainHash, _labelhash))] = _id;
            _ownerOf[_id] = msg.sender;
            emit Transfer(address(0), msg.sender, _id);
            unchecked{
                ++_id;
            }
        }
        unchecked {
            totalSupply = _mint;
            balanceOf[msg.sender] += num;
        }
    }

    /**
     * @dev
     * @param from : Address of Sender
     * @param to : Address of Receiver
     * @param id : NFT token ID
     */
    function _transfer(address from, address to, uint256 id, bytes memory data) internal {
        if (!active)
            revert ContractPaused();

        if (to == address(0))
            revert ZeroAddress();

        if (_ownerOf[id] != from)
            revert NotOwner(_ownerOf[id], from, id);

        if (
            msg.sender != _ownerOf[id] 
            && !isApprovedForAll[from][msg.sender] 
            && msg.sender != getApproved[id]
        ) revert NotAuthorized(msg.sender, from, id);

        ENS.setSubnodeOwner(
            DomainHash, ID2Labelhash[id], to
        );
        unchecked {
            --balanceOf[from]; // subtract from owner
            ++balanceOf[to]; // add to receiver
        }
        _ownerOf[id] = to; // change ownership
        delete getApproved[id]; // reset approved
        if (to.code.length > 0) {
            try iERC721Receiver(to).onERC721Received(msg.sender, from, id, data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector)
                    revert ERC721IncompatibleReceiver(to);
            } catch {
                revert ERC721IncompatibleReceiver(to);
            }
        }
        emit Transfer(from, to, id);
    }

    /**
     * @dev : Transfer Function
     * @param from : From Address
     * @param to : To Address
     * @param id : Token ID
     */
    function transferFrom(address from, address to, uint256 id) external payable {
        _transfer(from, to, id, "");
    }

    /**
     * @dev Safe Transfer From Function with extradata
     * @param from : From Address
     * @param to : To Address
     * @param id : Token ID
     * @param data : Extradata
     */
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external payable {
        _transfer(from, to, id, data);
    }

    /**
     * @dev Safe Transfer From Function
     * @param from : From Address
     * @param to : To Address
     * @param id : Token ID
     */
    function safeTransferFrom(address from, address to, uint256 id) external payable {
        _transfer(from, to, id, "");
    }

    /**
     * @dev
     * @param approved : Operator Address to be Approved
     * @param id : Token ID
     */
    function approve(address approved, uint256 id) external payable {
        if(msg.sender != _ownerOf[id])
            revert NotAuthorized(msg.sender, _ownerOf[id], id);

        getApproved[id] = approved;
        emit Approval(msg.sender, approved, id);
    }

    /**
     * @dev
     * @param operator : Operator Address to be Approved For ALL
     * @param approved : Bool to set
     */
    function setApprovalForAll(address operator, bool approved) external payable {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev
     * @param id : Token ID
     * @return : String IPFS path to Metadata .json file
     */
    function tokenURI(uint256 id) external view isValidToken(id) returns (string memory) {
        return string.concat("ipfs://", NFTData, "/", id.toString(), ".json");
    }

    /**
     * @dev
     * @param id :
     * @param _salePrice :
     * @return :
     */
    function royaltyInfo(uint256 id, uint256 _salePrice) external view returns (address, uint256){
        id; // silence warning
        return (Dev, (_salePrice / 100) * royalty);
    }

    // Contract Management

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
     * @param _contractURI :
     */
    function setContractURI(string calldata _contractURI) external onlyDev {
        contractURI = _contractURI;
    }

    // 
    /**
     * @dev EIP2981 royalty standard, 1 = 1 %
     * @param _royalty :
     */
    function setRoyalty(uint256 _royalty) external onlyDev {
        royalty = _royalty;
    }
}