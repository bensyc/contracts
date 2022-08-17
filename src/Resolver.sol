//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "src/Interface.sol";
import "src/Util.sol";
import "src/Base.sol";
/**
 * @title contract
 */
abstract contract Resolver is BENSYC {
    using Util for uint256;
    using Util for bytes;
    
    bytes public DefaultContenthash;

    constructor() {
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;
    }

    /**
     * @dev :
     * @param _content : Default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external onlyDev {
        DefaultContenthash = _content;
    }

    modifier isAuthorised(bytes32 node) {
        require(msg.sender == ENS.owner(node), "Resolver:Not_Authorised");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;

    function contenthash(bytes32 node) public view returns(bytes memory _hash) {
        _hash = _contenthash[node];
        if (_hash.length == 0) {
            return DefaultContenthash;
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);

    /**
     * @dev
     * @param node:
     * @param _hash:
     */
    function setContenthash(bytes32 node, bytes memory _hash) external isAuthorised(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;

    event AddrChanged(bytes32 indexed node, address a);

    /**
     * @dev
     * @param node :
     * @param _addr :
     */
    function setAddr(bytes32 node, address _addr) external isAuthorised(node) {
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddrChanged(node, _addr);
    }

    event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);

    /**
     * @dev
     * @param node :
     * @param coinType :
     */
    function setAddr(bytes32 node, uint256 coinType, bytes memory _addr) external isAuthorised(node) {
        _addrs[node][coinType] = _addr;
        emit AddressChanged(node, coinType, _addr);
    }

    /**
     * @dev
     * @param node :
     * @return :
     */
    function addr(bytes32 node) external view returns(address payable) {
        bytes memory _addr = _addrs[node][60];
        if (_addr.length == 0) {
            return payable(ENS.owner(node));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev
     * @param node :
     * @param coinType :
     * @return _addr :
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
     * @dev
     * @param node :
     * @param x :
     * @param y :
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external isAuthorised(node) {
        pubkey[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    mapping(bytes32 => mapping(string => string)) public _text;

    event TextChanged(bytes32 indexed node, string indexed key, string value);

    /**
     * @dev
     * @param node :
     * @param key :
     * @param value :
     */
    function setText(bytes32 node, string calldata key, string calldata value) external isAuthorised(node) {
        _text[node][key] = value;
        emit TextChanged(node, key, value);
    }

    /**
     * @dev
     * @param node :
     * @param key :
     * @return value :
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
     * @dev
     * @param node :
     * @param _name :
     */
    function setName(bytes32 node, string calldata _name) external isAuthorised(node) {
        _text[node]["name"] = _name;
        emit NameChanged(node, _name);
    }

    /**
     * @dev
     * @param node :
     * @return _name :
     */
    function name(bytes32 node) external view returns(string memory _name) {
        _name = _text[node]["name"];
        if(bytes(_name).length == 0) {
            _name = string.concat(
                Namehash2ID[node].toString(),
                ".BENSYC.ETH"
            );
        }
    }
}