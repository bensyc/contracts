//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;

import "src/Interface.sol";

/**
 * @title contract
 */
contract Resolver {
    //address Dev;
    iENS public ENS;
    iBENSYC public BENSYC;

    mapping(bytes4 => bool) public supportsInterface;
    bytes public DefaultContenthash;

    constructor(address _bensyc) {
        BENSYC = iBENSYC(_bensyc);

        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        // resolver
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true; 

        // supportsInterface[XCCIP.resolve.selector] = true;
    }

    error OnlyDev();

    /**
     * @dev :
     * @param _content : Default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external {
        if (msg.sender != BENSYC.Dev()) {
            revert OnlyDev();
        }
        DefaultContenthash = _content;
    }

    modifier isAuthorised(bytes32 node) {
        address _owner = ENS.owner(node);
        require(msg.sender == _owner, "Resolver:Not_Authorised");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;

    function contenthash(bytes32 node)
        public
        view
        returns (bytes memory _hash)
    {
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
    function setAddr(bytes32 node, address _addr) external isAuthorised(node){
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddrChanged(node, _addr);
    }

    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    /**
     * @dev
     * @param node :
     * @param coinType :
     */
    function setAddr(bytes32 node, uint256 coinType, bytes memory _addr) external isAuthorised(node){
        _addrs[node][coinType] = _addr;
        emit AddressChanged(node, coinType, _addr);
    }

    /**
     * @dev
     * @param node :
     * @return :
     */
    function addr(bytes32 node) external view returns (address payable) {
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
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory _addr){
        _addr = _addrs[node][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(ENS.owner(node));
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
    function setPubkey(bytes32 node, bytes32 x, bytes32 y)
        external
        isAuthorised(node)
    {
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
     * @param value :
     */
    function text(bytes32 node, string calldata key) external view returns(string memory value) {
        value = _text[node][key];
        if(bytes(value).length == 0){
            if(bytes32(bytes(key)) == bytes32(bytes("avatar"))){
                value = string.concat(
                    "eip155:", toString(block.chainid),
                    "/erc721:", toHexString(abi.encodePacked(address(BENSYC))), "/", toString(1));
                    // fix this ID
                //eip155:1/erc721:<address>/id
            } else {
                value = _text[bytes32(0)][key];
            }
        }
    }
    

    //mapping(bytes32 => string) public name;

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
       //if(bytes())
    }

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
    error NotAllowed();

    fallback() external payable {
        revert NotAllowed();
    }

    receive() external payable {
        revert NotAllowed();
    }

    function DESTROY() public {
        require(msg.sender == BENSYC.Dev());
        selfdestruct(payable(msg.sender));
    }
}