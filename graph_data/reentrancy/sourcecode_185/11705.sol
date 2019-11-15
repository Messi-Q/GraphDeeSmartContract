pragma solidity ^0.4.23;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Erc20Wallet {
  mapping (address => mapping (address => uint)) public tokens;  

  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  mapping (address => uint) public totalDeposited;

  function() public {
    revert();
  }

  modifier onlyToken (address token) {
    require( token != 0);
    _;
  }

  function commonDeposit(address token, uint value) internal {
    tokens[token][msg.sender] += value;
    totalDeposited[token] += value;
    emit Deposit(
      token,
      msg.sender,
      value,
      tokens[token][msg.sender]);
  }
  function commonWithdraw(address token, uint value) internal {
    require (tokens[token][msg.sender] >= value);
    tokens[token][msg.sender] -= value;
    totalDeposited[token] -= value;
    require((token != 0)?
      ERC20(token).transfer(msg.sender, value):
      msg.sender.call.value(value)()
    );
    emit Withdraw(
      token,
      msg.sender,
      value,
      tokens[token][msg.sender]);
  }

  function deposit() public payable {
    commonDeposit(0, msg.value);
  }
  function withdraw(uint amount) public {
    commonWithdraw(0, amount);
  }


  function depositToken(address token, uint amount) public onlyToken(token){
     
    require (ERC20(token).transferFrom(msg.sender, this, amount));
    commonDeposit(token, amount);
  }
  function withdrawToken(address token, uint amount) public {
    commonWithdraw(token, amount);
  }

  function balanceOf(address token, address user) public constant returns (uint) {
    return tokens[token][user];
  }
}


 
contract SplitErc20Payment is Erc20Wallet{
  using SafeMath for uint256;

  mapping (address => uint) public totalShares;
  mapping (address => uint) public totalReleased;

  mapping (address => mapping (address => uint)) public shares;  
  mapping (address => mapping (address => uint)) public released;  
  address[] public payees;

  function withdrawToken(address, uint) public{
    revert();
  }
  function withdraw(uint) public {
    revert();
  }

  function computePayeeBalance (address token, address payer, uint value) internal {
    if (shares[token][payer] == 0)
      addPayee(token, payer, value);
    else
      addToPayeeBalance(token, payer, value);
  }

  function deposit() public payable{
    super.deposit();
    computePayeeBalance(0, msg.sender, msg.value);
  }

  function depositToken(address token, uint amount) public{
     super.depositToken(token, amount);
     computePayeeBalance(token, msg.sender, amount);
  }

  function executeClaim(address token, address payee, uint payment) internal {
    require(payment != 0);
    require(totalDeposited[token] >= payment);

    released[token][payee] += payment;
    totalReleased[token] += payment;

    super.withdrawToken(token, payment);
  }

  function calculateMaximumPayment(address token, address payee)view internal returns(uint){
    require(shares[token][payee] > 0);
    uint totalReceived = totalDeposited[token] + totalReleased[token];
    return (totalReceived * shares[token][payee] / totalShares[token]) - released[token][payee];
  }

   
  function claim(address token) public {
    executeClaim(token, msg.sender, calculateMaximumPayment(token, msg.sender));
  }

   
  function partialClaim(address token, uint payment) public {
    uint maximumPayment = calculateMaximumPayment(token, msg.sender);

    require (payment <= maximumPayment);

    executeClaim(token, msg.sender, payment);
  }

   
  function addPayee(address token, address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[token][_payee] == 0);

    payees.push(_payee);
    shares[token][_payee] = _shares;
    totalShares[token] += _shares;
  }
   
  function addToPayeeBalance(address token, address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[token][_payee] > 0);

    shares[token][_payee] += _shares;
    totalShares[token] += _shares;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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


contract InvestmentRecordList is Ownable{
    event NoRecordFound(InvestmentRecord _investmentRecord);

    InvestmentRecord[] internal investmentRecords;

    function getInvestmentRecord (uint index) public view returns (InvestmentRecord){
        return investmentRecords[index];
    }
    function getInvestmentRecordListLength () public view returns (uint){
        return investmentRecords.length;
    }

    function pushRecord (InvestmentRecord _investmentRecord) onlyOwner public{
        investmentRecords.push(_investmentRecord);
    }

    function popRecord (InvestmentRecord _investmentRecord) onlyOwner public{
        uint index;
        bool foundRecord;
        (index, foundRecord) = getIndex(_investmentRecord);
        if (! foundRecord){
            emit NoRecordFound(_investmentRecord);
            revert();
        }
        InvestmentRecord recordToDelete = investmentRecords[investmentRecords.length-1];
        investmentRecords[index] = recordToDelete;
        delete recordToDelete;
        investmentRecords.length--;
    }

    function getIndex (InvestmentRecord _investmentRecord) public view returns (uint index, bool foundRecord){
        foundRecord = false;
        for (index = 0; index < investmentRecords.length; index++){
            if (investmentRecords[index] == _investmentRecord){
                foundRecord = true;
                break;
            }
        }
    }
}

contract InvestmentRecord {
    using SafeMath for uint256;

    address public token;
    uint public timeStamp;
    uint public lockPeriod;
    uint public value;

    constructor (address _token, uint _timeStamp, uint _lockPeriod, uint _value) public{
        token = _token;
        timeStamp = _timeStamp;
        lockPeriod = _lockPeriod;
        value = _value;
    }

    function expiredLockPeriod () public view returns (bool){
        return now >= timeStamp + lockPeriod;
    }

    function getValue () public view returns (uint){
        return value;
    }
    
    function getToken () public view returns (address){
        return token;
    }    
}


contract ERC20Vault is SplitErc20Payment{
  using SafeMath for uint256;
  mapping (address => InvestmentRecordList) public pendingInvestments;

  function withdrawToken(address, uint) public {
    revert();
  }

  function getLockedValue (address token) public returns (uint){
    InvestmentRecordList investmentRecordList = pendingInvestments[msg.sender];
    if (investmentRecordList == address(0x0))
      return 0;

    uint lockedValue = 0;
    for(uint8 i = 0; i < investmentRecordList.getInvestmentRecordListLength(); i++){
      InvestmentRecord investmentRecord = investmentRecordList.getInvestmentRecord(i);
      if (investmentRecord.getToken() == token){
        if (investmentRecord.expiredLockPeriod()){
            investmentRecordList.popRecord(investmentRecord);
        }else{
          uint valueToAdd = investmentRecord.getValue();
          lockedValue += valueToAdd;
        }
      }
    }
    return lockedValue;
  }
  function claim(address token) public{
    uint lockedValue = getLockedValue(token);
    uint actualBalance = this.balanceOf(token, msg.sender);
    require(actualBalance > lockedValue);

    super.partialClaim(token, actualBalance - lockedValue);
  }

  function partialClaim(address token, uint payment) public{
    uint lockedValue = getLockedValue(token);
    uint actualBalance = this.balanceOf(token, msg.sender);
    require(actualBalance - lockedValue >= payment);

    super.partialClaim(token, payment);
  }

  function depositTokenToVault(address token, uint amount, uint lockPeriod) public{
    if (pendingInvestments[msg.sender] == address(0x0)){
      pendingInvestments[msg.sender] = new InvestmentRecordList();
    }
    super.depositToken(token, amount);
    pendingInvestments[msg.sender].pushRecord(new InvestmentRecord(token, now, lockPeriod, amount));
  }
}