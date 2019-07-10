pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
















 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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







 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}










 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract BullToken is BurnableToken, PausableToken {

  string public constant name = "BullToken";
  string public constant symbol = "BULL";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 55000000;
  bool public transferEnabled;

  mapping (address => bool) public isHolder;
  address [] public holders;

  function BullToken() public {
    totalSupply = INITIAL_SUPPLY * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
    transferEnabled = false;
  }

  function enableTransfers() onlyOwner public {
    transferEnabled = true;
    TransferEnabled();
  }

  function disableTransfers() onlyOwner public {
    transferEnabled = false;
    TransferDisabled();
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(transferEnabled || msg.sender == owner);

     
    if (!isHolder[to]) {
      holders.push(to);
      isHolder[to] = true;
    }

    return super.transfer(to, value);
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(transferEnabled || from == owner);

     
    if (!isHolder[to]) {
      holders.push(to);
      isHolder[to] = true;
    }

    return super.transferFrom(from, to, value);
  }

  event TransferEnabled();
  event TransferDisabled();

}





 
contract Curatable is Ownable {
  address public curator;


  event CurationRightsTransferred(address indexed previousCurator, address indexed newCurator);


   
  function Curatable() public {
    owner = msg.sender;
    curator = owner;
  }


   
  modifier onlyCurator() {
    require(msg.sender == curator);
    _;
  }


   
  function transferCurationRights(address newCurator) public onlyOwner {
    require(newCurator != address(0));
    CurationRightsTransferred(curator, newCurator);
    curator = newCurator;
  }

}


contract Whitelist is Curatable {
    mapping (address => bool) public whitelist;


    function Whitelist() public {
    }


    function addInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && !whitelist[investor]);
        whitelist[investor] = true;
    }


    function removeInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && whitelist[investor]);
        whitelist[investor] = false;
    }


    function isWhitelisted(address investor) constant external returns (bool result) {
        return whitelist[investor];
    }

}





 
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






 
contract BurnableCrowdsale {
  using SafeMath for uint256;

   
  BurnableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  address public tokenAddress;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function BurnableCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenAddress) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    tokenAddress = _tokenAddress;
    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
   
  function createTokenContract() internal returns (BurnableToken) {
    return new BurnableToken();
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
     
  }

   
   
  function forwardFunds() internal {
     
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

}


 
contract CappedCrowdsale is BurnableCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}












 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


contract BullTokenRefundVault is RefundVault {

  function BullTokenRefundVault(address _wallet) public RefundVault(_wallet) {}

   
  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
     
     
    wallet.call.value(this.balance)();
  }

  function forwardFunds() onlyOwner public {
    require(this.balance > 0);
    wallet.call.value(this.balance)();
  }
}







 
contract FinalizableCrowdsale is BurnableCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}



 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  BullTokenRefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new BullTokenRefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}


contract BullTokenCrowdsale is CappedCrowdsale, RefundableCrowdsale {
  using SafeMath for uint256;

  Whitelist public whitelist;
  uint256 public minimumInvestment;

  function BullTokenCrowdsale(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    uint256 _goal,
    uint256 _cap,
    uint256 _minimumInvestment,
    address _tokenAddress,
    address _wallet,
    address _whitelistAddress
  ) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    BurnableCrowdsale(_startTime, _endTime, _rate, _wallet, _tokenAddress)
  {
     
     
    require(_goal <= _cap);

    whitelist = Whitelist(_whitelistAddress);
    minimumInvestment = _minimumInvestment;
  }

  function createTokenContract() internal returns (BurnableToken) {
    return BullToken(tokenAddress);
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(whitelist.isWhitelisted(beneficiary));

    uint256 weiAmount = msg.value;
    uint256 raisedIncludingThis = weiRaised.add(weiAmount);

    if (raisedIncludingThis > cap) {
      require(hasStarted() && !hasEnded());
      uint256 toBeRefunded = raisedIncludingThis.sub(cap);
      weiAmount = cap.sub(weiRaised);
      beneficiary.transfer(toBeRefunded);
    } else {
      require(validPurchase());
    }

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.transferFrom(owner, beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFundsToWallet(weiAmount);
  }

   
   
  function validPurchase() internal view returns (bool) {
    return super.validPurchase() && aboveMinimumInvestment();
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised.add(minimumInvestment) > cap;
    return super.hasEnded() || capReached;
  }

   
  function hasStarted() public constant returns (bool) {
    return now >= startTime;
  }

  function aboveMinimumInvestment() internal view returns (bool) {
    return msg.value >= minimumInvestment;
  }

  function forwardFundsToWallet(uint256 amount) internal {
    if (goalReached() && vault.balance > 0) {
      vault.forwardFunds();
    }

    if (goalReached()) {
      wallet.call.value(amount)();
    } else {
      vault.deposit.value(amount)(msg.sender);
    }
  }

}