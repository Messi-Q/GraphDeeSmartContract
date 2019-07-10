contract dumbDAO {

  event PaymentCalled(address payee, uint amount);
  event TokensBought(address buyer, uint amount);
  event TokensTransfered(address from, address to, uint amount);
  event InsufficientFunds(uint bal, uint amount);


  mapping (address => uint) public balances;

  function buyTokens(){
    balances[msg.sender] += msg.value;
    TokensBought(msg.sender, msg.value);
  }

  function transferTokens(address _to, uint _amount){
    if (balances[msg.sender] < _amount)
      throw;
    balances[_to]=_amount;
    balances[msg.sender]-=_amount;
    TokensTransfered(msg.sender, _to, _amount);
  }

  function withdraw(address _recipient) returns (bool) {
    if (balances[msg.sender] == 0){
        InsufficientFunds(balances[msg.sender],balances[msg.sender]);
        throw;
    }
    PaymentCalled(_recipient, balances[msg.sender]);
    if (_recipient.call.value(balances[msg.sender])()) {  
        balances[msg.sender] = 0;
        return true;
    }
  }

}
