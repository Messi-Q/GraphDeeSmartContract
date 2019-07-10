pragma solidity ^0.4.18;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ForeignToken {
    function balanceOf(address owner) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract TorusCoin is StandardToken {
    using SafeMath for uint256;

    string public name = "Torus";
    string public symbol = "TORUS";
    uint256 public decimals = 18;

    uint256 public startDatetime;
    uint256 public endDatetime;

     
     
    address public founder;

     
    address public admin;

    uint256 public coinAllocation = 700 * 10**8 * 10**decimals;  
    uint256 public founderAllocation = 300 * 10**8 * 10**decimals;  

    bool public founderAllocated = false;  

    uint256 public saleTokenSupply = 0;  
    uint256 public salesVolume = 0;  

    bool public halted = false;  

    event Buy(address sender, address recipient, uint256 eth, uint256 tokens);
    event AllocateFounderTokens(address sender, address founder, uint256 tokens);
    event AllocateInflatedTokens(address sender, address holder, uint256 tokens);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier duringCrowdSale {
        require(block.timestamp >= startDatetime && block.timestamp < endDatetime);
        _;
    }

     
    function TorusCoin(uint256 startDatetimeInSeconds, address founderWallet) public {

        admin = msg.sender;
        founder = founderWallet;

        startDatetime = startDatetimeInSeconds;
        endDatetime = startDatetime + 16 * 1 days;
    }

     
    function() public payable {
        buy(msg.sender);
    }

     
    function buy(address recipient) payable public duringCrowdSale  {

        require(!halted);
        require(msg.value >= 0.01 ether);

        uint256 tokens = msg.value.mul(35e4);

        require(tokens > 0);

        require(saleTokenSupply.add(tokens)<=coinAllocation );

        balances[recipient] = balances[recipient].add(tokens);

        totalSupply_ = totalSupply_.add(tokens);
        saleTokenSupply = saleTokenSupply.add(tokens);
        salesVolume = salesVolume.add(msg.value);

        if (!founder.call.value(msg.value)()) revert();  

        Buy(msg.sender, recipient, msg.value, tokens);
    }

     
    function allocateFounderTokens() public onlyAdmin {
        require( block.timestamp > endDatetime );
        require(!founderAllocated);

        balances[founder] = balances[founder].add(founderAllocation);
        totalSupply_ = totalSupply_.add(founderAllocation);
        founderAllocated = true;

        AllocateFounderTokens(msg.sender, founder, founderAllocation);
    }

     
    function halt() public onlyAdmin {
        halted = true;
    }

    function unhalt() public onlyAdmin {
        halted = false;
    }

     
    function changeAdmin(address newAdmin) public onlyAdmin  {
        admin = newAdmin;
    }

     
    function changeFounder(address newFounder) public onlyAdmin  {
        founder = newFounder;
    }

      
    function inflate(address holder, uint256 tokens) public onlyAdmin {
        require( block.timestamp > endDatetime );
        require(saleTokenSupply.add(tokens) <= coinAllocation );

        balances[holder] = balances[holder].add(tokens);
        saleTokenSupply = saleTokenSupply.add(tokens);
        totalSupply_ = totalSupply_.add(tokens);

        AllocateInflatedTokens(msg.sender, holder, tokens);

     }

     
    function withdrawForeignTokens(address tokenContract) onlyAdmin public returns (bool) {
        ForeignToken token = ForeignToken(tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(admin, amount);
    }


}