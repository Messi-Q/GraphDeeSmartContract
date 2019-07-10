pragma solidity ^0.4.18;
 
contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

 
contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract StandardToken is Token {

     
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


 
contract AutomobileCyberchainToken is StandardToken, SafeMath {

    string public name = "Automobile Cyberchain Token";
    string public symbol = "AMCC";
    uint public decimals = 18;
    uint preSalePrice  = 32000;
    uint crowSalePrice = 20000;
    uint prePeriod = 256 * 24 * 30; 
    uint totalPeriod = 256 * 24 * 95;  
    uint public startBlock = 5455280;  
    uint public endBlock = startBlock + totalPeriod;  


     
     
     
    address public founder = 0xfD16CDC79382F86303E2eE8693C7f50A4d8b937F;
    uint256 public preEtherCap = 15625 * 10**18;  
    uint256 public etherCap =    88125 * 10**18;  
    uint256 public bountyAllocation = 1050000000 * 10**18;
    uint256 public maxToken = 3000000000 * 10**18;
     
     

    uint256 public presaleTokenSupply = 0;  
    uint256 public totalEtherRaised = 0;
    bool public halted = false;  

    event Buy(address indexed sender, uint eth, uint fbt);


    function AutomobileCyberchainToken() {
        balances[founder] = bountyAllocation;
        totalSupply = bountyAllocation;
        Transfer(address(0), founder, bountyAllocation);
    }


    function price() constant returns(uint) {
        if (block.number<startBlock || block.number > endBlock) return 0;  
        else if (block.number>=startBlock && block.number<startBlock+prePeriod) return preSalePrice;  
        else  return crowSalePrice;  
    }

    
    function() public payable  {
        buyToken(msg.sender, msg.value);
    }


     
    function buy(address recipient, uint256 value) public payable {
        if (value> msg.value) throw;

        if (value < msg.value) {
            require(msg.sender.call.value(msg.value - value)());  
        }
        buyToken(recipient, value);
    }


    function buyToken(address recipient, uint256 value) internal {
        if (block.number<startBlock || block.number>endBlock || safeAdd(totalEtherRaised,value)>etherCap || halted) throw;
        if (block.number>=startBlock && block.number<=startBlock+prePeriod && safeAdd(totalEtherRaised,value) > preEtherCap) throw;  
        uint tokens = safeMul(value, price());
        balances[recipient] = safeAdd(balances[recipient], tokens);
        totalSupply = safeAdd(totalSupply, tokens);
        totalEtherRaised = safeAdd(totalEtherRaised, value);

        if (block.number<=startBlock+prePeriod) {
            presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
        }
        Transfer(address(0), recipient, tokens);  
        if (!founder.call.value(value)()) throw;  
        Buy(recipient, value, tokens);  

    }


     
    function halt() {
        if (msg.sender!=founder) throw;
        halted = true;
    }

    function unhalt() {
        if (msg.sender!=founder) throw;
        halted = false;
    }

     
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) throw;
        founder = newFounder;
    }

    function withdrawExtraToken(address recipient) public {
      require(msg.sender == founder && block.number > endBlock && totalSupply < maxToken);

      uint256 leftTokens = safeSub(maxToken, totalSupply);
      balances[recipient] = safeAdd(balances[recipient], leftTokens);
      totalSupply = maxToken;
      Transfer(address(0), recipient, leftTokens);
    }


     
     
     
     
     


     
     
     
     
     
}