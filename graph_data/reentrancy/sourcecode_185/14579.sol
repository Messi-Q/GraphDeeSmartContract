 
pragma solidity ^0.4.21;

 

 
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

 

contract ICOStartSaleInterface {
  ERC20 public token;
}

contract ICOStartReservation is Pausable {
  using SafeMath for uint256;

  ICOStartSaleInterface public sale;
  uint256 public cap;
  uint8 public feePerc;
  address public manager;
  mapping(address => uint256) public deposits;
  uint256 public weiCollected;
  uint256 public tokensReceived;
  bool public canceled;
  bool public paid;

  event Deposited(address indexed depositor, uint256 amount);
  event Withdrawn(address indexed beneficiary, uint256 amount);
  event Paid(uint256 netAmount, uint256 fee);
  event Canceled();

  function ICOStartReservation(ICOStartSaleInterface _sale, uint256 _cap, uint8 _feePerc, address _manager) public {
    require(_sale != (address(0)));
    require(_cap != 0);
    require(_feePerc >= 0);
    if (_feePerc != 0) {
      require(_manager != 0x0);
    }

    sale = _sale;
    cap = _cap;
    feePerc = _feePerc;
    manager = _manager;
  }

   
  modifier whenOpen() {
    require(isOpen());
    _;
  }

   
  modifier whenNotCanceled() {
    require(!canceled);
    _;
  }

   
  modifier whenCanceled() {
    require(canceled);
    _;
  }

   
  modifier whenNotPaid() {
    require(!paid);
    _;
  }

   
  modifier whenPaid() {
    require(paid);
    _;
  }

   
  function capReached() public view returns (bool) {
    return weiCollected >= cap;
  }

   
  function getToken() public view returns (ERC20) {
    return sale.token();
  }

   
  function isOpen() public view returns (bool) {
    return !paused && !capReached() && !canceled && !paid;
  }

   
  function () external payable {
    if (msg.value == 0) {
      claimTokens(msg.sender);
    } else {
      deposit(msg.sender);
    }
  }

   
  function deposit(address _depositor) public whenOpen payable {
    require(_depositor != address(0));
    require(weiCollected.add(msg.value) <= cap);
    deposits[_depositor] = deposits[_depositor].add(msg.value);
    weiCollected = weiCollected.add(msg.value);
    emit Deposited(_depositor, msg.value);
  }

   
  function cancel() public onlyOwner whenPaused whenNotPaid {
    canceled = true;
  }

   
  function pay() public onlyOwner whenNotCanceled {
    require(weiCollected > 0);
  
    uint256 fee;
    uint256 netAmount;
    (fee, netAmount) = _getFeeAndNetAmount(weiCollected);

    require(address(sale).call.value(netAmount)(this));
    tokensReceived = getToken().balanceOf(this);

    if (fee != 0) {
      manager.transfer(fee);
    }

    paid = true;
    emit Paid(netAmount, fee);
  }

   
  function withdraw() public whenCanceled {
    uint256 depositAmount = deposits[msg.sender];
    require(depositAmount != 0);
    deposits[msg.sender] = 0;
    weiCollected = weiCollected.sub(depositAmount);
    msg.sender.transfer(depositAmount);
    emit Withdrawn(msg.sender, depositAmount);
  }

   
  function claimTokens(address _beneficiary) public whenPaid {
    require(_beneficiary != address(0));
    
    uint256 depositAmount = deposits[_beneficiary];
    if (depositAmount != 0) {
      uint256 tokens = tokensReceived.mul(depositAmount).div(weiCollected);
      assert(tokens != 0);
      deposits[_beneficiary] = 0;
      getToken().transfer(_beneficiary, tokens);
    }
  }

   
  function destroy() onlyOwner public {
    uint256 myTokens = getToken().balanceOf(this);
    if (myTokens != 0) {
      getToken().transfer(owner, myTokens);
    }
    selfdestruct(owner);
  }

   

   
   function _getFeeAndNetAmount(uint256 _grossAmount) internal view returns (uint256 _fee, uint256 _netAmount) {
      _fee = _grossAmount.div(100).mul(feePerc);
      _netAmount = _grossAmount.sub(_fee);
   }
}