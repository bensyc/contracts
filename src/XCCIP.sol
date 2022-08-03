//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0;
import "src/Interface.sol";

abstract contract Base {

    iBENSYC public BENSYC;
    iENS public ENS;

    fallback() external payable {
        revert();
    }

    receive() external payable{
        revert();
    }
    
    function withdraw() external {
        require(msg.sender == BENSYC.Dev());
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdraw(address _token, uint _bal) external {
        require(msg.sender == BENSYC.Dev());
        iToken(_token).transferFrom(address(this), msg.sender, _bal);
    }

    function DESTROY() external {
        require(msg.sender == BENSYC.Dev());
        selfdestruct(payable(msg.sender));
    }
}

contract XCCIP is Base {

    address public PrimaryResolver;
    
    bytes32 public immutable secondaryLabelHash = keccak256(bytes("bensyc"));
    bytes32 public immutable secondaryDomainHash;

    //bytes32 public immutable primaryLabelHash = keccak256(bytes("boredensyachtclub"));
    bytes32 public immutable primaryDomainHash;
    
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    error InvalidTokenID(string id, uint index);
    error InvalidParentDomain(string str);
    error InvalidNamehash(bytes32 expected, bytes32 provided);
    error RequestError(bytes32 expected, bytes32 check, bytes data, uint blknum, bytes result);
    error StaticCallFailed(address resolver, bytes _call);
    
    function supportsInterface(bytes4 sig) external pure returns(bool){
        return (sig == XCCIP.resolve.selector || sig == XCCIP.supportsInterface.selector);
    }
    
    constructor(address _bensyc) {
        bytes32 _base = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        secondaryDomainHash = keccak256(abi.encodePacked(_base, secondaryLabelHash));
        primaryDomainHash = keccak256(abi.encodePacked(_base,  keccak256(bytes("boredensyachtclub"))));
        BENSYC = iBENSYC(_bensyc);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function dnsDecode(bytes calldata name) public view returns(bytes32) {
        uint i;
        uint j;
        bytes[] memory labels = new bytes[](7);

        while(name[i] != 0x0){
            uint len = uint8(bytes1(name[i : ++i]));
            labels[j] =  name[i : i += len];
            j++;
        }
        
        if(keccak256(labels[1]) != secondaryLabelHash){
            revert InvalidParentDomain(string(labels[1]));
        }
        i = 0;
        for(j = 0; j < labels[0].length; j++){
            if(labels[0][j] < 0x30 || labels[0][j] > 0x39){
                revert InvalidTokenID(string(labels[0]), i);
            }
            i = (i * 10) + (uint8(labels[0][j]) - 48);
        }
        if(i >= BENSYC.totalSupply()){
            revert InvalidTokenID(string(labels[0]), 10_000);
        }
        return keccak256(labels[0]);
    }

    function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory) {
        bytes32 _callhash;
        if(bytes32(data[4:36]) == secondaryDomainHash){
            _callhash = primaryDomainHash;
        } else {
            _callhash = dnsDecode(name);
            if(keccak256(abi.encodePacked(secondaryDomainHash, _callhash)) != bytes32(data[4:36])){
                // extra check
                revert InvalidNamehash(
                    keccak256(abi.encodePacked(secondaryDomainHash, _callhash)), 
                    bytes32(data[4:36])
                );
            }
            _callhash = keccak256(abi.encodePacked(primaryDomainHash, _callhash));
        }
        

        bytes memory _result = getResult(_callhash, data);  
        string[] memory _urls = new string[](1);
        _urls[0] = 'data:text/plain,{"data":"{data}"}';
        revert OffchainLookup(
            address(this),
            _urls,
            _result,
            XCCIP.resolveWithoutProof.selector,
            abi.encode(keccak256(abi.encodePacked(msg.sender, address(this), data, block.number, _result)), block.number, data)
        );
    }
    
    function getResult(bytes32 _primaryNamehash, bytes calldata data) public view returns(bytes memory){
        ///bytes32 _primaryNamehash = (_labelhash == secondaryDomainHash)? 
        //    primaryDomainHash : keccak256(abi.encodePacked(primaryDomainHash, _labelhash));

        bytes memory _call =  (data.length > 36) ? 
            abi.encodePacked(data[:4], _primaryNamehash, data[36:]) : 
            abi.encodePacked(data[:4], _primaryNamehash);

        address _resolver = ENS.resolver(_primaryNamehash);
        (bool _success, bytes memory _result) = _resolver.staticcall(_call);  
        if (!_success || _result.length == 0){
            revert StaticCallFailed(_resolver, _call);
        }
        return _result;
    }

    /**
     * Callback used by CCIP read compatible clients to verify and parse the response.
     */
    function resolveWithoutProof(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (bytes32 hash, uint blknum, bytes memory data) = abi.decode(extraData, (bytes32, uint, bytes));
        bytes32 check = keccak256(abi.encodePacked(msg.sender, address(this), data, blknum, response));
        if(check != hash || block.number > blknum + 5){ // extra check
            revert RequestError(hash, check, data, blknum, response);
        }
        return response;
    }
}