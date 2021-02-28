pragma solidity ^0.4.8;
contract Victim {
   
  mapping(address => uint) public balances;
   
  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
        if(msg.sender.call.value(_amount)()) {
            _amount;
        }
        balances[msg.sender] -= _amount;
    }
  }
  function deposit() payable {}
}
