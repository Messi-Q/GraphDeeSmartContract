pragma solidity ^0.4.16;

 
 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract RequestSale {
   
  mapping (address => uint256) public balances;
   
  bool public bought_tokens;
   
  uint256 public contract_eth_value;
   
  uint256 public eth_cap = 500 ether;
   
  uint256 constant public min_required_amount = 60 ether;
   
  address public owner;
   
  address public sale = 0xa579E31b930796e3Df50A56829cF82Db98b6F4B3;
  
   
  function RequestSale() {
    owner = msg.sender;
  }
  
   
   
  function perform_withdrawal(address tokenAddress) {
     
    require(bought_tokens);
     
    ERC20 token = ERC20(tokenAddress);
    uint256 contract_token_balance = token.balanceOf(address(this));
     
    require(contract_token_balance != 0);
     
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
     
    contract_eth_value -= balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
   
  function refund_me() {
     
    uint256 eth_to_withdraw = balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens() {
    require(msg.sender == owner);
    require(!bought_tokens);
    require(sale != 0x0);
    require(this.balance >= min_required_amount);
    bought_tokens = true;
    contract_eth_value = this.balance;
    require(sale.call.value(contract_eth_value)());
  }

  function upgrade_cap() {
     
    require(msg.sender == owner);
     
    eth_cap = 1000 ether;
    
  }
  
   
  function () payable {
     
    require(!bought_tokens);
     
    require(this.balance + msg.value < eth_cap);
     
    balances[msg.sender] += msg.value;
  }
}