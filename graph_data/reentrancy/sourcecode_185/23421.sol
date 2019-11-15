pragma solidity ^0.4.20;

 

 
contract ERC20 {
  
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
 
 
 
 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    function Owned() public {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     
     
     
     
     
     
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
     
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 

 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

         
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

 
 
contract Multiplexor is Escapable {
    function Multiplexor() Escapable(0, 0) public {}
    
    function init(address _escapeHatchCaller, address _escapeHatchDestination) public {
        require(escapeHatchCaller == 0);
        require(_escapeHatchCaller != 0);
        require(_escapeHatchDestination != 0);
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    function multiTransferTightlyPacked(bytes32[] _addressAndAmount) payable public returns(bool) {
        for (uint i = 0; i < _addressAndAmount.length; i++) {
            _safeTransfer(address(_addressAndAmount[i] >> 96), uint(uint96(_addressAndAmount[i])));
        }
        return true;
    }

    function multiTransfer(address[] _address, uint[] _amount) payable public returns(bool) {
        for (uint i = 0; i < _address.length; i++) {
            _safeTransfer(_address[i], _amount[i]);
        }
        return true;
    }

    function multiCallTightlyPacked(bytes32[] _addressAndAmount) payable public returns(bool) {
        for (uint i = 0; i < _addressAndAmount.length; i++) {
            _safeCall(address(_addressAndAmount[i] >> 96), uint(uint96(_addressAndAmount[i])));
        }
        return true;
    }

    function multiCall(address[] _address, uint[] _amount) payable public returns(bool) {
        for (uint i = 0; i < _address.length; i++) {
            _safeCall(_address[i], _amount[i]);
        }
        return true;
    }

    function multiERC20TransferTightlyPacked(ERC20 _token, bytes32[] _addressAndAmount) public returns(bool) {
        for (uint i = 0; i < _addressAndAmount.length; i++) {
            _safeERC20Transfer(_token, address(_addressAndAmount[i] >> 96), uint(uint96(_addressAndAmount[i])));
        }
        return true;
    }

    function multiERC20Transfer(ERC20 _token, address[] _address, uint[] _amount) public returns(bool) {
        for (uint i = 0; i < _address.length; i++) {
            _safeERC20Transfer(_token, _address[i], _amount[i]);
        }
        return true;
    }

    function _safeTransfer(address _to, uint _amount) internal {
        require(_to != 0);
        _to.transfer(_amount);
    }

    function _safeCall(address _to, uint _amount) internal {
        require(_to != 0);
        require(_to.call.value(_amount)());
    }

    function _safeERC20Transfer(ERC20 _token, address _to, uint _amount) internal {
        require(_to != 0);
        require(_token.transferFrom(msg.sender, _to, _amount));
    }
}