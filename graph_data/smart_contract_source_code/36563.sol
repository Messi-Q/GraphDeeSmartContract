pragma solidity ^0.4.11;


 
contract Ownable {
  address owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract SharkProxy is Ownable {

  event Deposit(address indexed sender, uint256 value);
  event Withdrawal(address indexed to, uint256 value, bytes data);

  function SharkProxy() {
    owner = msg.sender;
  }

  function getOwner() constant returns (address) {
    return owner;
  }

  function forward(address _destination, uint256 _value, bytes _data) onlyOwner {
    require(_destination != address(0));
    assert(_destination.call.value(_value)(_data));  
    if (_value > 0) {
      Withdrawal(_destination, _value, _data);
    }
  }

   
  function() payable {
    Deposit(msg.sender, msg.value);
  }

   
  function tokenFallback(address _from, uint _value, bytes _data) {
  }

}


contract FishProxy is SharkProxy {

   
  address lockAddr;

  function FishProxy(address _owner, address _lockAddr) {
    owner = _owner;
    lockAddr = _lockAddr;
  }

  function isLocked() constant returns (bool) {
    return lockAddr != 0x0;
  }

  function unlock(bytes32 _r, bytes32 _s, bytes32 _pl) {
    assert(lockAddr != 0x0);
     
    uint8 v;
    uint88 target;
    address newOwner;
    assembly {
        v := calldataload(37)
        target := calldataload(48)
        newOwner := calldataload(68)
    }
     
    assert(target == uint88(address(this)));
    assert(newOwner == msg.sender);
    assert(newOwner != owner);
    assert(ecrecover(sha3(uint8(0), target, newOwner), v, _r, _s) == lockAddr);
     
    owner = newOwner;
    lockAddr = 0x0;
  }

   
  function() payable {
     
     
     
    assert(lockAddr == address(0) || this.balance <= 1e17);
    Deposit(msg.sender, msg.value);
  }

}


contract FishFactory {

  event AccountCreated(address proxy);

  function create(address _owner, address _lockAddr) {
    address proxy = new FishProxy(_owner, _lockAddr);
    AccountCreated(proxy);
  }

}