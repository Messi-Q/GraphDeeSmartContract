pragma solidity ^0.4.24;



library SafeMath {
   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {

    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
library SafeERC20 {
  function safeTransfer(ERC20 _token, address _to, uint256 _value) internal {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _value) internal {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(ERC20 _token, address _spender, uint256 _value) internal {
    require(_token.approve(_spender, _value));
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
   }

}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender) public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract AddressesFilterFeature is Ownable {}
contract ERC20Basic {}
contract BasicToken is ERC20Basic {}
contract StandardToken is ERC20, BasicToken {}
contract MintableToken is AddressesFilterFeature, StandardToken {}

contract Token is MintableToken {
    function mint(address, uint256) public returns (bool);
}

contract CrowdsaleWPTByRounds is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

  address public wallet;

  Token public minterContract;

  uint256 public rate;

  uint256 public tokensRaised;

   
  uint256 public cap;

   
  uint256 public openingTime;
  uint256 public closingTime;

   
  uint public minInvestmentValue;
  
   
  bool public checksOn;

   
  uint256 public gasAmount;

   
  function setMinter(address _minterAddr) public onlyOwner {
    minterContract = Token(_minterAddr);
  }

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
    );

   
  event TokensTransfer(
    address indexed _from,
    address indexed _to,
    uint256 amount,
    bool isDone
    );

constructor () public {
    rate = 400;
    wallet = 0xeA9cbceD36a092C596e9c18313536D0EEFacff46;
    cap = 400000000000000000000000;
    openingTime = 1534558186;
    closingTime = 1535320800;

    minInvestmentValue = 0.02 ether;
    
    checksOn = true;
    gasAmount = 25000;
  }

    
  function capReached() public view returns (bool) {
    return tokensRaised >= cap;
  }

    
  function changeRate(uint256 newRate) public onlyOwner {
    rate = newRate;
  }

    
  function closeRound() public onlyOwner {
    closingTime = block.timestamp + 1;
  }

    
  function setToken(ERC20 _token) public onlyOwner {
    token = _token;
  }

    
  function setWallet(address _wallet) public onlyOwner {
    wallet = _wallet;
  }

    
  function changeMinInvest(uint256 newMinValue) public onlyOwner {
    rate = newMinValue;
  }

    
  function setChecksOn(bool _checksOn) public onlyOwner {
    checksOn = _checksOn;
  }

    
  function setGasAmount(uint256 _gasAmount) public onlyOwner {
    gasAmount = _gasAmount;
  }

    
  function setCap(uint256 _newCap) public onlyOwner {
    cap = _newCap;
  }

    
  function startNewRound(uint256 _rate, address _wallet, ERC20 _token, uint256 _cap, uint256 _openingTime, uint256 _closingTime) payable public onlyOwner {
    require(!hasOpened());
    rate = _rate;
    wallet = _wallet;
    token = _token;
    cap = _cap;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function hasOpened() public view returns (bool) {
     
    return (openingTime < block.timestamp && block.timestamp < closingTime);
  }

  function () payable external {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) payable public{
    uint256 weiAmount = msg.value;
    if (checksOn) {
        _preValidatePurchase(_beneficiary, weiAmount);
    }
    uint256 tokens = _getTokenAmount(weiAmount);

    tokensRaised = tokensRaised.add(tokens);

    minterContract.mint(_beneficiary, tokens);
    
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds();
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen {
    require(_beneficiary != address(0));
    require(_weiAmount != 0 && _weiAmount > minInvestmentValue);
    require(tokensRaised.add(_getTokenAmount(_weiAmount)) <= cap);
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    bool isTransferDone = wallet.call.value(msg.value).gas(gasAmount)();
    emit TokensTransfer (msg.sender, wallet, msg.value, isTransferDone);
  }
}