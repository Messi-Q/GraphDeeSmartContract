 

pragma solidity ^0.4.13;

contract RegBaseAbstract
{
     
     
     
    bytes32 public regName;

     
     
     
    bytes32 public resource;
    
     
     
    address public owner;
    
     
     
    address public newOwner;

 
 
 

     
    event ChangeOwnerTo(address indexed _newOwner);

     
    event ChangedOwner(address indexed _oldOwner, address indexed _newOwner);

     
    event ReceivedOwnership(address indexed _kAddr);

     
    event ChangedResource(bytes32 indexed _resource);

 
 
 

     
    function destroy() public;

     
     
    function changeOwner(address _owner) public returns (bool);

     
    function acceptOwnership() public returns (bool);

     
     
    function changeResource(bytes32 _resource) public returns (bool);
}


contract RegBase is RegBaseAbstract
{
 
 
 

    bytes32 constant public VERSION = "RegBase v0.3.3";

 
 
 

     
     
     
    
 
 
 

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 
 
 

     
     
     
     
     
     
     
    function RegBase(address _creator, bytes32 _regName, address _owner)
    {
        require(_regName != 0x0);
        regName = _regName;
        owner = _owner != 0x0 ? _owner : 
                _creator != 0x0 ? _creator : msg.sender;
    }
    
     
    function destroy()
        public
        onlyOwner
    {
        selfdestruct(msg.sender);
    }
    
     
     
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        ChangeOwnerTo(_owner);
        newOwner = _owner;
        return true;
    }
    
     
    function acceptOwnership()
        public
        returns (bool)
    {
        require(msg.sender == newOwner);
        ChangedOwner(owner, msg.sender);
        owner = newOwner;
        delete newOwner;
        return true;
    }

     
     
    function changeResource(bytes32 _resource)
        public
        onlyOwner
        returns (bool)
    {
        resource = _resource;
        ChangedResource(_resource);
        return true;
    }
}

 

pragma solidity ^0.4.13;

 

contract Factory is RegBase
{
 
 
 

     
     
     

     
     
     
     

 
 
 

     
    uint public value;

 
 
 

     
    event Created(address indexed _creator, bytes32 indexed _regName, address indexed _addr);

 
 
 

     
    modifier feePaid() {
        require(msg.value == value || msg.sender == owner);
        _;
    }

 
 
 

     
     
     
     
     
     
     
    function Factory(address _creator, bytes32 _regName, address _owner)
        RegBase(_creator, _regName, _owner)
    {
         
    }
    
     
     
    function set(uint _fee) 
        onlyOwner
        returns (bool)
    {
        value = _fee;
        return true;
    }

     
    function withdrawAll()
        public
        returns (bool)
    {
        owner.transfer(this.balance);
        return true;
    }

     
     
     
     
     
     
    function createNew(bytes32 _regName, address _owner) 
        payable returns(address kAddr_);
}

 

pragma solidity ^0.4.13;

 

contract Forwarder is RegBase {
 
 
 

    bytes32 constant public VERSION = "Forwarder v0.3.0";

 
 
 

    address public forwardTo;
    
 
 
 
    
    event Forwarded(
        address indexed _from,
        address indexed _to,
        uint _value);

 
 
 

    function Forwarder(address _creator, bytes32 _regName, address _owner)
        public
        RegBase(_creator, _regName, _owner)
    {
         
         
        forwardTo = owner;
    }
    
    function() public payable {
        Forwarded(msg.sender, forwardTo, msg.value);
        require(forwardTo.call.value(msg.value)(msg.data));
    }
    
    function changeForwardTo(address _forwardTo)
        public
        returns (bool)
    {
         
        require(msg.sender == owner || msg.sender == forwardTo);
        forwardTo = _forwardTo;
        return true;
    }
}


contract ForwarderFactory is Factory
{
 
 
 

     
    bytes32 constant public regName = "forwarder";
    
     
    bytes32 constant public VERSION = "ForwarderFactory v0.3.0";

 
 
 

     
     
     
     
     
     
     
    function ForwarderFactory(
            address _creator, bytes32 _regName, address _owner) public
        Factory(_creator, regName, _owner)
    {
         
         
    }

     
     
     
     
     
     
    function createNew(bytes32 _regName, address _owner)
        public
        payable
        feePaid
        returns (address kAddr_)
    {
        kAddr_ = address(new Forwarder(msg.sender, _regName, _owner));
        Created(msg.sender, _regName, kAddr_);
    }
}