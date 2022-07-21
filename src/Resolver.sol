//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;
import "src/Interface.sol";

/**
 * @title contract 
 */
contract Resolver {
    address Dev;
    iENS public ENS;
    mapping(bytes4 => bool) public supportsInterface;
    bytes public DefaultContenthash;
    constructor(){

        Dev = msg.sender;
        
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        // resolver
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;
        // CCIP
        // supportsInterface[iCCIP.resolve.selector] = true;
    }

    error OnlyDev();
    /**
    * @dev : 
    * @param _content : Default contenthash to set
    */
    function setDefaultContenthash(bytes memory _content) external {
        if(msg.sender != Dev){
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
    function contenthash(bytes32 node) public view returns(bytes memory _hash){
        _hash = _contenthash[node];
        if(_hash.length == 0){
            return DefaultContenthash;
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);

    /**
     * @dev
     * @param node:
     * @param _hash:
     */
    function setContenthash(
        bytes32 node,
        bytes memory _hash
    ) external isAuthorised(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint => bytes)) internal _addrs;
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

    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    /**
     * @dev
     * @param node :
     * @param coinType :
     */
    function setAddr(bytes32 node, uint coinType, bytes memory _addr) virtual public isAuthorised(node) {
        if (coinType == 60) {
            emit AddrChanged(node, address(uint160(uint256(bytes32(_addr)))));
        } else {
            emit AddressChanged(node, coinType, _addr);
        }
        _addrs[node][coinType] = _addr;
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
     * @return :
     */
    function addr(bytes32 node, uint coinType) external view returns(bytes memory) {
        bytes memory _addr = _addrs[node][coinType];
        if (_addr.length == 0 && coinType == 60) {
            return abi.encodePacked(ENS.owner(node));
        }
        return _addr;
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

    mapping(bytes32 => mapping(string => string)) public text;
    event TextChanged(bytes32 indexed node, string indexed key, string value);
    /**
     * @dev
     * @param node :
     * @param key :
     * @param value :
     */
    function setText(bytes32 node, string calldata key, string calldata value) virtual external isAuthorised(node) {
        text[node][key] = value;
        emit TextChanged(node, key, value);
    }
    
    mapping(bytes32 => string) public name;
    event NameChanged(bytes32 indexed node, string name);
    /**
    * @dev
    * @param node :
    * @param _name :
    */
    function setName(bytes32 node, string calldata _name) external isAuthorised(node) {
            name[node] = _name;
            emit NameChanged(node, _name);
    }
    
    /// 
    error NotAllowed();
    fallback() external payable{
        revert NotAllowed();
    }

    receive() external payable{
        revert NotAllowed();
    }
    function DESTROY() public {
        require(msg.sender == Dev);
        selfdestruct(payable(msg.sender));
    }    
}
