pragma solidity ^0.4.13;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    emit Transfer(msg.sender, _to, _value);
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

contract HasManager {
  address public manager;

  modifier onlyManager {
    require(msg.sender == manager);
    _;
  }

  function transferManager(address _newManager) public onlyManager() {
    require(_newManager != address(0));
    manager = _newManager;
  }
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;
  address public whitelistManager;
  function AddToWhiteList(address _addr) public {
      require(msg.sender == whitelistManager || msg.sender == owner);
      whitelist[_addr] = true;
  }

  function AssignWhitelistManager(address _addr) public onlyOwner {
      whitelistManager = _addr;
  }

  modifier whitelistedOnly {
    require(whitelist[msg.sender]);
    _;
  }
}

contract WithBonusPeriods is Ownable {
  uint256 constant INVALID_FROM_TIMESTAMP = 1000000000000;
  uint256 constant INFINITY_TO_TIMESTAMP= 1000000000000;
  struct BonusPeriod {
    uint256 fromTimestamp;
    uint256 toTimestamp;
    uint256 bonusNumerator;
    uint256 bonusDenominator;
  }

  BonusPeriod[] public bonusPeriods;
  BonusPeriod currentBonusPeriod;

  function WithBonusPeriods() public {
      initBonuses();
  }

  function BonusPeriodsCount() public view returns (uint8) {
    return uint8(bonusPeriods.length);
  }

   
  function BonusPeriodFor(uint256 timestamp) public view returns (bool ongoing, uint256 from, uint256 to, uint256 num, uint256 den) {
    for(uint i = 0; i < bonusPeriods.length; i++)
      if (bonusPeriods[i].fromTimestamp <= timestamp && bonusPeriods[i].toTimestamp >= timestamp)
        return (true, bonusPeriods[i].fromTimestamp, bonusPeriods[i].toTimestamp, bonusPeriods[i].bonusNumerator,
          bonusPeriods[i].bonusDenominator);
    return (false, 0, 0, 0, 0);
  }

  function initBonusPeriod(uint256 from, uint256 to, uint256 num, uint256 den) internal  {
    bonusPeriods.push(BonusPeriod(from, to, num, den));
  }

  function initBonuses() internal {
       
      initBonusPeriod(1525132800, 1525737599, 20, 100);
       
      initBonusPeriod(1525737600, 1526342399, 15, 100);
       
      initBonusPeriod(1526342400, 1526947199, 10, 100);
       
      initBonusPeriod(1526947200, 1527551999, 5, 100);
  }

  function updateCurrentBonusPeriod() internal  {
    if (currentBonusPeriod.fromTimestamp <= block.timestamp
      && currentBonusPeriod.toTimestamp >= block.timestamp)
      return;

    currentBonusPeriod.fromTimestamp = INVALID_FROM_TIMESTAMP;

    for(uint i = 0; i < bonusPeriods.length; i++)
      if (bonusPeriods[i].fromTimestamp <= block.timestamp && bonusPeriods[i].toTimestamp >= block.timestamp) {
        currentBonusPeriod = bonusPeriods[i];
        return;
      }
  }
}

contract ICrowdsaleProcessor is Ownable, HasManager {
  modifier whenCrowdsaleAlive() {
    require(isActive());
    _;
  }

  modifier whenCrowdsaleFailed() {
    require(isFailed());
    _;
  }

  modifier whenCrowdsaleSuccessful() {
    require(isSuccessful());
    _;
  }

  modifier hasntStopped() {
    require(!stopped);
    _;
  }

  modifier hasBeenStopped() {
    require(stopped);
    _;
  }

  modifier hasntStarted() {
    require(!started);
    _;
  }

  modifier hasBeenStarted() {
    require(started);
    _;
  }

   
  uint256 constant public MIN_HARD_CAP = 1 ether;

   
  uint256 constant public MIN_CROWDSALE_TIME = 3 days;

   
  uint256 constant public MAX_CROWDSALE_TIME = 50 days;

   
  bool public started;

   
  bool public stopped;

   
  uint256 public totalCollected;

   
  uint256 public totalSold;

   
  uint256 public minimalGoal;

   
  uint256 public hardCap;

   
   
  uint256 public duration;

   
  uint256 public startTimestamp;

   
  uint256 public endTimestamp;

   
  function deposit() public payable {}

   
  function getToken() public returns(address);

   
  function mintETHRewards(address _contract, uint256 _amount) public onlyManager();

   
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();

   
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful();

   
   
  function stop() public onlyManager() hasntStopped();

   
  function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress)
    public onlyManager() hasntStarted() hasntStopped();

   
  function isFailed() public constant returns (bool);

   
  function isActive() public constant returns (bool);

   
  function isSuccessful() public constant returns (bool);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Crowdsaled is Ownable {
        address public crowdsaleContract = address(0);
        function Crowdsaled() public {
        }

        modifier onlyCrowdsale{
          require(msg.sender == crowdsaleContract);
          _;
        }

        modifier onlyCrowdsaleOrOwner {
          require((msg.sender == crowdsaleContract) || (msg.sender == owner));
          _;
        }

        function setCrowdsale(address crowdsale) public onlyOwner() {
                crowdsaleContract = crowdsale;
        }
}

contract LetItPlayToken is Crowdsaled, StandardToken {
        uint256 public totalSupply;
        string public name;
        string public symbol;
        uint8 public decimals;

        address public forSale;
        address public preSale;
        address public ecoSystemFund;
        address public founders;
        address public team;
        address public advisers;
        address public bounty;
        address public eosShareDrop;

        bool releasedForTransfer;

        uint256 private shift;

         
        function LetItPlayToken(
            address _forSale,
            address _ecoSystemFund,
            address _founders,
            address _team,
            address _advisers,
            address _bounty,
            address _preSale,
            address _eosShareDrop
          ) public {
          name = "LetItPlay Token";
          symbol = "PLAY";
          decimals = 8;
          shift = uint256(10)**decimals;
          totalSupply = 1000000000 * shift;
          forSale = _forSale;
          ecoSystemFund = _ecoSystemFund;
          founders = _founders;
          team = _team;
          advisers = _advisers;
          bounty = _bounty;
          eosShareDrop = _eosShareDrop;
          preSale = _preSale;

          balances[forSale] = totalSupply * 59 / 100;
          balances[ecoSystemFund] = totalSupply * 15 / 100;
          balances[founders] = totalSupply * 15 / 100;
          balances[team] = totalSupply * 5 / 100;
          balances[advisers] = totalSupply * 3 / 100;
          balances[bounty] = totalSupply * 1 / 100;
          balances[preSale] = totalSupply * 1 / 100;
          balances[eosShareDrop] = totalSupply * 1 / 100;
        }

        function transferByOwner(address from, address to, uint256 value) public onlyOwner {
          require(balances[from] >= value);
          balances[from] = balances[from].sub(value);
          balances[to] = balances[to].add(value);
          emit Transfer(from, to, value);
        }

         
        function transferByCrowdsale(address to, uint256 value) public onlyCrowdsale {
          require(balances[forSale] >= value);
          balances[forSale] = balances[forSale].sub(value);
          balances[to] = balances[to].add(value);
          emit Transfer(forSale, to, value);
        }

         
        function transferFromByCrowdsale(address _from, address _to, uint256 _value) public onlyCrowdsale returns (bool) {
            return super.transferFrom(_from, _to, _value);
        }

         
        function releaseForTransfer() public onlyCrowdsaleOrOwner {
          require(!releasedForTransfer);
          releasedForTransfer = true;
        }

         
        function transfer(address _to, uint256 _value) public returns (bool) {
          require(releasedForTransfer);
          return super.transfer(_to, _value);
        }

         
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
           require(releasedForTransfer);
           return super.transferFrom(_from, _to, _value);
        }

        function burn(uint256 value) public  onlyOwner {
            require(value <= balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[address(0)] = balances[address(0)].add(value);
            emit Transfer(msg.sender, address(0), value);
        }
}

contract BasicCrowdsale is ICrowdsaleProcessor {
  event CROWDSALE_START(uint256 startTimestamp, uint256 endTimestamp, address fundingAddress);

   
  address public fundingAddress;

   
  function BasicCrowdsale(
    address _owner,
    address _manager
  )
    public
  {
    owner = _owner;
    manager = _manager;
  }

   
   
   
   
  function mintETHRewards(address _contract,  uint256 _amount) public onlyManager() {
    require(_contract.call.value(_amount)());
  }

   
  function stop() public onlyManager() hasntStopped()  {
     
    if (started) {
      require(!isFailed());
      require(!isSuccessful());
    }
    stopped = true;
  }

   
   
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    onlyManager()    
    hasntStarted()   
    hasntStopped()   
  {
    require(_fundingAddress != address(0));

     
    require(_startTimestamp >= block.timestamp);

     
    require(_endTimestamp > _startTimestamp);
    duration = _endTimestamp - _startTimestamp;

     
    require(duration >= MIN_CROWDSALE_TIME && duration <= MAX_CROWDSALE_TIME);

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    fundingAddress = _fundingAddress;

     
    started = true;

    emit CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

   
  function isFailed()
    public
    constant
    returns(bool)
  {
    return (
       
      started &&

       
      block.timestamp >= endTimestamp &&

       
      totalCollected < minimalGoal
    );
  }

   
  function isActive()
    public
    constant
    returns(bool)
  {
    return (
       
      started &&

       
      totalCollected < hardCap &&

       
      block.timestamp >= startTimestamp &&
      block.timestamp < endTimestamp
    );
  }

   
  function isSuccessful()
    public
    constant
    returns(bool)
  {
    return (
       
      totalCollected >= hardCap ||

       
      (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
    );
  }
}

contract Crowdsale is BasicCrowdsale, Whitelist, WithBonusPeriods {

  struct Investor {
    uint256 weiDonated;
    uint256 tokensGiven;
  }

  mapping(address => Investor) participants;

  uint256 public tokenRateWei;
  LetItPlayToken public token;

   
  function Crowdsale(
    uint256 _minimalGoal,
    uint256 _hardCap,
    uint256 _tokenRateWei,
    address _token
  )
    public
     
     
    BasicCrowdsale(msg.sender, msg.sender)
  {
     
    minimalGoal = _minimalGoal;
    hardCap = _hardCap;
    tokenRateWei = _tokenRateWei;
    token = LetItPlayToken(_token);
  }

   

   
  function getToken()
    public
    returns(address)
  {
    return address(token);
  }

   
   
   
  function mintTokenRewards(
    address _contract,   
    uint256 _amount      
  )
    public
    onlyManager()  
  {
     
    token.transferByCrowdsale(_contract, _amount);
  }

   
  function releaseTokens()
    public
    onlyManager()              
    hasntStopped()             
    whenCrowdsaleSuccessful()  
  {
     
    token.releaseForTransfer();
  }

  function () payable public {
    require(msg.value > 0);
    sellTokens(msg.sender, msg.value);
  }

  function sellTokens(address _recepient, uint256 _value)
    internal
    hasBeenStarted()
    hasntStopped()
    whenCrowdsaleAlive()
    whitelistedOnly()
  {
    uint256 newTotalCollected = totalCollected + _value;

    if (hardCap < newTotalCollected) {
      uint256 refund = newTotalCollected - hardCap;
      uint256 diff = _value - refund;
      _recepient.transfer(refund);
      _value = diff;
    }

    uint256 tokensSold = _value * uint256(10)**token.decimals() / tokenRateWei;

     
    updateCurrentBonusPeriod();
    if (currentBonusPeriod.fromTimestamp != INVALID_FROM_TIMESTAMP)
      tokensSold += tokensSold * currentBonusPeriod.bonusNumerator / currentBonusPeriod.bonusDenominator;

    token.transferByCrowdsale(_recepient, tokensSold);
    participants[_recepient].weiDonated += _value;
    participants[_recepient].tokensGiven += tokensSold;
    totalCollected += _value;
    totalSold += tokensSold;
  }

   
  function withdraw(uint256 _amount) public  
    onlyOwner()  
    hasntStopped()   
    whenCrowdsaleSuccessful()  
  {
    require(_amount <= address(this).balance);
    fundingAddress.transfer(_amount);
  }

   
  function refund() public
  {
     
    require(stopped || isFailed());

    uint256 weiDonated = participants[msg.sender].weiDonated;
    uint256 tokens = participants[msg.sender].tokensGiven;

     
    require(weiDonated > 0);
    participants[msg.sender].weiDonated = 0;
    participants[msg.sender].tokensGiven = 0;

    msg.sender.transfer(weiDonated);

     
    token.transferFromByCrowdsale(msg.sender, token.forSale(), tokens);
  }
}