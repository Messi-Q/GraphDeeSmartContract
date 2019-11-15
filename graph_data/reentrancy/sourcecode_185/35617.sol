pragma solidity ^0.4.11;

 

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

  function safeDiv(uint a, uint b) internal returns (uint) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
  }
}

 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


 
contract MoldCoin is StandardToken, SafeMath {

    string public name = "MOLD";
    string public symbol = "MLD";
    uint public decimals = 18;

    uint public startDatetime;  
    uint public firstStageDatetime;  
    uint public secondStageDatetime;  
    uint public endDatetime;  

     
     
    address public founder;

     
    address public admin;

    uint public coinAllocation = 20 * 10**8 * 10**decimals;  
    uint public angelAllocation = 2 * 10**8 * 10**decimals;  
    uint public founderAllocation = 3 * 10**8 * 10**decimals;  

    bool public founderAllocated = false;  

    uint public saleTokenSupply = 0;  
    uint public salesVolume = 0;  

    uint public angelTokenSupply = 0;  

    bool public halted = false;  

    event Buy(address indexed sender, uint eth, uint tokens);
    event AllocateFounderTokens(address indexed sender, uint tokens);
    event AllocateAngelTokens(address indexed sender, address to, uint tokens);
    event AllocateUnsoldTokens(address indexed sender, address holder, uint tokens);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier duringCrowdSale {
        require(block.timestamp >= startDatetime && block.timestamp <= endDatetime);
        _;
    }

     
    function MoldCoin(uint startDatetimeInSeconds, address founderWallet) {

        admin = msg.sender;
        founder = founderWallet;
        startDatetime = startDatetimeInSeconds;
        firstStageDatetime = startDatetime + 120 * 1 hours;
        secondStageDatetime = firstStageDatetime + 240 * 1 hours;
        endDatetime = secondStageDatetime + 2040 * 1 hours;

    }

     
    function price(uint timeInSeconds) constant returns(uint) {
        if (timeInSeconds < startDatetime) return 0;
        if (timeInSeconds <= firstStageDatetime) return 15000;  
        if (timeInSeconds <= secondStageDatetime) return 12000;  
        if (timeInSeconds <= endDatetime) return 10000;  
        return 0;
    }

     
    function buy() payable {
        buyRecipient(msg.sender);
    }

    function() payable {
        buyRecipient(msg.sender);
    }

     
    function buyRecipient(address recipient) duringCrowdSale payable {
        require(!halted);

        uint tokens = safeMul(msg.value, price(block.timestamp));
        require(safeAdd(saleTokenSupply,tokens)<=coinAllocation );

        balances[recipient] = safeAdd(balances[recipient], tokens);

        totalSupply = safeAdd(totalSupply, tokens);
        saleTokenSupply = safeAdd(saleTokenSupply, tokens);
        salesVolume = safeAdd(salesVolume, msg.value);

        if (!founder.call.value(msg.value)()) revert();  

        Buy(recipient, msg.value, tokens);
    }

     
    function allocateFounderTokens() onlyAdmin {
        require( block.timestamp > endDatetime );
        require(!founderAllocated);

        balances[founder] = safeAdd(balances[founder], founderAllocation);
        totalSupply = safeAdd(totalSupply, founderAllocation);
        founderAllocated = true;

        AllocateFounderTokens(msg.sender, founderAllocation);
    }

     
    function allocateAngelTokens(address angel, uint tokens) onlyAdmin {

        require(safeAdd(angelTokenSupply,tokens) <= angelAllocation );

        balances[angel] = safeAdd(balances[angel], tokens);
        angelTokenSupply = safeAdd(angelTokenSupply, tokens);
        totalSupply = safeAdd(totalSupply, tokens);

        AllocateAngelTokens(msg.sender, angel, tokens);
    }

     
    function halt() onlyAdmin {
        halted = true;
    }

    function unhalt() onlyAdmin {
        halted = false;
    }

     
    function changeAdmin(address newAdmin) onlyAdmin  {
        admin = newAdmin;
    }

     
    function arrangeUnsoldTokens(address holder, uint256 tokens) onlyAdmin {
        require( block.timestamp > endDatetime );
        require( safeAdd(saleTokenSupply,tokens) <= coinAllocation );
        require( balances[holder] >0 );

        balances[holder] = safeAdd(balances[holder], tokens);
        saleTokenSupply = safeAdd(saleTokenSupply, tokens);
        totalSupply = safeAdd(totalSupply, tokens);

        AllocateUnsoldTokens(msg.sender, holder, tokens);

    }

}


contract MoldCoinBonus is SafeMath {

    function bonusBalanceOf(address _owner) constant returns (uint256 balance) {
        return bonusBalances[_owner];
    }

    mapping (address => uint256) bonusBalances;

     
    address public admin;

     
    MoldCoin public fundAddress;
    uint public rate = 10;
    uint public totalSupply = 0;

    bool public halted = false;  

    event BuyWithBonus(address indexed sender, address indexed inviter, uint eth, uint tokens, uint bonus);
    event BuyForFriend(address indexed sender, address indexed friend, uint eth, uint tokens, uint bonus);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier validSale {
        require(!halted);
        require(!fundAddress.halted());
        _;
    }

    function MoldCoinBonus(MoldCoin _fundAddress, uint _rate) {

        admin = msg.sender;
        fundAddress = _fundAddress;
        rate = _rate;

    }

    function buyWithBonus(address inviter) validSale payable {

        require( msg.sender != inviter );

        uint tokens = safeMul(msg.value, fundAddress.price(block.timestamp));
        uint bonus = safeDiv(safeMul(tokens, rate), 100);

        fundAddress.buyRecipient.value(msg.value)(msg.sender);  

        totalSupply = safeAdd(totalSupply, bonus*2);

        bonusBalances[inviter] = safeAdd(bonusBalances[inviter], bonus);
        bonusBalances[msg.sender] = safeAdd(bonusBalances[msg.sender], bonus);
        BuyWithBonus(msg.sender, inviter, msg.value, tokens, bonus);

    }


     
    function halt() onlyAdmin {
        halted = true;
    }

    function unhalt() onlyAdmin {
        halted = false;
    }

     
    function changeAdmin(address newAdmin) onlyAdmin  {
        admin = newAdmin;
    }

    function changeRate(uint _rate) onlyAdmin  {
        rate = _rate;
    }

}