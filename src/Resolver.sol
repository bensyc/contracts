//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";
import "src/Util.sol";
import "src/Base.sol";

/**
 * @title BENSYC Resolver
 */

abstract contract Resolver is BENSYC {
    using Util for uint256;
    using Util for bytes;
    

    /// @notice : encoder: https://gist.github.com/sshmatrix/6ed02d73e439a5773c5a2aa7bd0f90f9
    /// @dev : default contenthash (encoded from IPNS hash) 
    //  IPNS : k51qzi5uqu5dkco782zzu13xwmoz6yijezzk326uo0097cr8tits04eryrf5n3
    bytes public DefaultContenthash = "0xe5010170003e6b3531717a693575717535646b636f3738327a7a75313378776d6f7a3679696a657a7a6b333236756f303039376372387469747330346572797266356e33";

    constructor() {
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;
    }

    /**
     * @dev : sets default contenthash
     * @param _content : default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external onlyDev {
        DefaultContenthash = _content;
    }

    /**
     * @dev : verify ownership of subdomain
     * @param node : subdomain
     */
    modifier isOwner(bytes32 node) {
        require(msg.sender == ENS.owner(node), "Resolver: NOT_AUTHORISED");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;
    /**
     * @dev : return default contenhash if no contenthash set
     * @param node : subdomain
     */
    function contenthash(bytes32 node) public view returns(bytes memory _hash) {
        _hash = _contenthash[node];
        if (_hash.length == 0) {
            return DefaultContenthash;
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);
    /**
     * @dev : change contenthash of subdomain
     * @param node: subdomain
     * @param _hash: new contenthash
     */
    function setContenthash(bytes32 node, bytes memory _hash) external isOwner(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;
    event AddressChanged(bytes32 indexed node, address a);
    /**
     * @dev : change address of subdomain
     * @param node : subdomain
     * @param _addr : new address
     */
    function setAddress(bytes32 node, address _addr) external isOwner(node) {
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddressChanged(node, _addr);
    }

    event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);
    /**
     * @dev : change address of subdomain for <coin>
     * @param node : subdomain
     * @param coinType : <coin>
     */
    function setAddress(bytes32 node, uint256 coinType, bytes memory _addr) external isOwner(node) {
        _addrs[node][coinType] = _addr;
        emit AddressChanged(node, coinType, _addr);
    }

    /**
     * @dev : default subdomain to owner if no address is set for Ethereum [60]
     * @param node : sundomain
     * @return : resolved address 
     */
    function addr(bytes32 node) external view returns(address payable) {
        bytes memory _addr = _addrs[node][60];
        if (_addr.length == 0) {
            return payable(ENS.owner(node));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

     /**
     * @dev : resolve subdomain addresses for <coin>; if no ethereum address [60] is set, resolve to owner
     * @param node : sundomain
     * @param coinType : <coin>
     * @return _addr : resolved address 
     */
    function addr(bytes32 node, uint256 coinType) external view returns(bytes memory _addr) {
        _addr = _addrs[node][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(_ownerOf[Namehash2ID[node]]);
        }
    }

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }
    mapping(bytes32 => PublicKey) public pubkey;
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    /**
     * @dev : change public key record
     * @param node : subdomain
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external isOwner(node) {
        pubkey[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    mapping(bytes32 => mapping(string => string)) public _text;
    event TextRecordChanged(bytes32 indexed node, string indexed key, string value);
    /**
     * @dev : change text record
     * @param node : subdomain
     * @param key : key to change
     * @param value : value to set
     */
    function setText(bytes32 node, string calldata key, string calldata value) external isOwner(node) {
        _text[node][key] = value;
        emit TextRecordChanged(node, key, value);
    }

    /**
     * @dev : get text records
     * @param node : subdomain
     * @param key : key to query
     * @return value : value
     */
    function text(bytes32 node, string calldata key) external view returns(string memory value) {
        value = _text[node][key];
        if (bytes(value).length == 0) {
            if (bytes32(bytes(key)) == bytes32(bytes("avatar"))) {
                return string.concat(
                    "eip155:", block.chainid.toString(),
                    "/erc721:", abi.encodePacked(DefaultResolver).toHexString(), 
                    "/", Namehash2ID[node].toString()
                );
            } else {
                return _text[bytes32(0)][key];
            }
        }
    }

    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev : change name record
     * @param node : subdomain
     * @param _name : new name
     */
    function setName(bytes32 node, string calldata _name) external isOwner(node) {
        _text[node]["name"] = _name;
        emit NameChanged(node, _name);
    }

    /**
     * @dev : get default name at mint
     * @param node : subdomain
     * @return _name : default name
     */
    function name(bytes32 node) external view returns(string memory _name) {
        _name = _text[node]["name"];
        if(bytes(_name).length == 0) {
            return string.concat(
                Namehash2ID[node].toString(),
                ".BENSYC.ETH"
            );
        }
    }
}