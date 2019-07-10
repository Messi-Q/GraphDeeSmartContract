pragma solidity ^0.4.19;

 
 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


contract ERC20 {
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
}


contract WhiteList {
   function checkMemberLevel (address addr) view public returns (uint) {}
}


contract PresalePool {

   
   
  using SafeMath for uint;
  
   
   
   
   
   
  uint8 public contractStage = 1;
  
   
   
  address public owner;
   
  uint[] public contributionCaps;
   
  uint public feePct;
   
  address public receiverAddress;
  
   
   
  uint constant public contributionMin = 100000000000000000;
   
  uint constant public maxGasPrice = 50000000000;
   
  WhiteList constant public whitelistContract = WhiteList(0x8D95B038cA80A986425FA240C3C17Fb2B6e9bc63);
  
  
   
   
  uint public nextCapTime;
   
  uint [] public nextContributionCaps;
   
  uint public addressChangeBlock;
   
  uint public finalBalance;
   
  uint[] public ethRefundAmount;
   
  address public activeToken;
  
   
  struct Contributor {
    bool authorized;
    uint ethRefund;
    uint balance;
    uint cap;
    mapping (address => uint) tokensClaimed;
  }
   
  mapping (address => Contributor) whitelist;
  
   
  struct TokenAllocation {
    ERC20 token;
    uint[] pct;
    uint balanceRemaining;
  }
   
  mapping (address => TokenAllocation) distributionMap;
  
  
   
  modifier onlyOwner () {
    require (msg.sender == owner);
    _;
  }
  
   
  bool locked;
  modifier noReentrancy() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }
  
   
   
  event ContributorBalanceChanged (address contributor, uint totalBalance);
  event ReceiverAddressSet ( address _addr);
  event PoolSubmitted (address receiver, uint amount);
  event WithdrawalsOpen (address tokenAddr);
  event EthRefundReceived (address sender, uint amount);
  event EthRefunded (address receiver, uint amount);
  event TokensWithdrawn (address receiver, address token, uint amount);
  event ERC223Received (address token, uint value);
   
   
   
  function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
    return numerator.mul(10 ** 20) / denominator;
  }
  
   
  function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
    return numerator.mul(pct) / (10 ** 20);
  }
  
   
   
  function PresalePool(address receiverAddr, uint[] capAmounts, uint fee) public {
    require (fee < 100);
    require (capAmounts.length>1 && capAmounts.length<256);
    for (uint8 i=1; i<capAmounts.length; i++) {
      require (capAmounts[i] <= capAmounts[0]);
    }
    owner = msg.sender;
    receiverAddress = receiverAddr;
    contributionCaps = capAmounts;
    feePct = _toPct(fee,100);
    whitelist[msg.sender].authorized = true;
  }
  
   
   
   
  function () payable public {
    if (contractStage == 1) {
      _ethDeposit();
    } else if (contractStage == 3) {
      _ethRefund();
    } else revert();
  }
  
   
  function _ethDeposit () internal {
    assert (contractStage == 1);
    require (tx.gasprice <= maxGasPrice);
    require (this.balance <= contributionCaps[0]);
    var c = whitelist[msg.sender];
    uint newBalance = c.balance.add(msg.value);
    require (newBalance >= contributionMin);
    require (newBalance <= _checkCap(msg.sender));
    c.balance = newBalance;
    ContributorBalanceChanged(msg.sender, newBalance);
  }
  
   
  function _ethRefund () internal {
    assert (contractStage == 3);
    require (msg.sender == owner || msg.sender == receiverAddress);
    require (msg.value >= contributionMin);
    ethRefundAmount.push(msg.value);
    EthRefundReceived(msg.sender, msg.value);
  }
  
   
   
   
   
   
  function withdraw (address tokenAddr) public {
    var c = whitelist[msg.sender];
    require (c.balance > 0);
    if (contractStage < 3) {
      uint amountToTransfer = c.balance;
      c.balance = 0;
      msg.sender.transfer(amountToTransfer);
      ContributorBalanceChanged(msg.sender, 0);
    } else {
      _withdraw(msg.sender,tokenAddr);
    }  
  }
  
   
  function withdrawFor (address contributor, address tokenAddr) public onlyOwner {
    require (contractStage == 3);
    require (whitelist[contributor].balance > 0);
    _withdraw(contributor,tokenAddr);
  }
  
   
   
  function _withdraw (address receiver, address tokenAddr) internal {
    assert (contractStage == 3);
    var c = whitelist[receiver];
    if (tokenAddr == 0x00) {
      tokenAddr = activeToken;
    }
    var d = distributionMap[tokenAddr];
    require ( (ethRefundAmount.length > c.ethRefund) || d.pct.length > c.tokensClaimed[tokenAddr] );
    if (ethRefundAmount.length > c.ethRefund) {
      uint pct = _toPct(c.balance,finalBalance);
      uint ethAmount = 0;
      for (uint i=c.ethRefund; i<ethRefundAmount.length; i++) {
        ethAmount = ethAmount.add(_applyPct(ethRefundAmount[i],pct));
      }
      c.ethRefund = ethRefundAmount.length;
      if (ethAmount > 0) {
        receiver.transfer(ethAmount);
        EthRefunded(receiver,ethAmount);
      }
    }
    if (d.pct.length > c.tokensClaimed[tokenAddr]) {
      uint tokenAmount = 0;
      for (i=c.tokensClaimed[tokenAddr]; i<d.pct.length; i++) {
        tokenAmount = tokenAmount.add(_applyPct(c.balance,d.pct[i]));
      }
      c.tokensClaimed[tokenAddr] = d.pct.length;
      if (tokenAmount > 0) {
        require(d.token.transfer(receiver,tokenAmount));
        d.balanceRemaining = d.balanceRemaining.sub(tokenAmount);
        TokensWithdrawn(receiver,tokenAddr,tokenAmount);
      }  
    }
    
  }
  
   
   
   
  function authorize (address addr, uint cap) public onlyOwner {
    require (contractStage == 1);
    _checkWhitelistContract(addr);
    require (!whitelist[addr].authorized);
    require ((cap > 0 && cap < contributionCaps.length) || (cap >= contributionMin && cap <= contributionCaps[0]) );
    uint size;
    assembly { size := extcodesize(addr) }
    require (size == 0);
    whitelist[addr].cap = cap;
    whitelist[addr].authorized = true;
  }
  
   
   
  function authorizeMany (address[] addr, uint cap) public onlyOwner {
    require (addr.length < 255);
    require (cap > 0 && cap < contributionCaps.length);
    for (uint8 i=0; i<addr.length; i++) {
      authorize(addr[i], cap);
    }
  }
  
   
   
   
  function revoke (address addr) public onlyOwner {
    require (contractStage < 3);
    require (whitelist[addr].authorized);
    require (whitelistContract.checkMemberLevel(addr) == 0);
    whitelist[addr].authorized = false;
    if (whitelist[addr].balance > 0) {
      uint amountToTransfer = whitelist[addr].balance;
      whitelist[addr].balance = 0;
      addr.transfer(amountToTransfer);
      ContributorBalanceChanged(addr, 0);
    }
  }
  
   
   
  function modifyIndividualCap (address addr, uint cap) public onlyOwner {
    require (contractStage < 3);
    require (cap < contributionCaps.length || (cap >= contributionMin && cap <= contributionCaps[0]) );
    _checkWhitelistContract(addr);
    var c = whitelist[addr];
    require (c.authorized);
    uint amount = c.balance;
    c.cap = cap;
    uint capAmount = _checkCap(addr);
    if (amount > capAmount) {
      c.balance = capAmount;
      addr.transfer(amount.sub(capAmount));
      ContributorBalanceChanged(addr, capAmount);
    }
  }
  
   
   
  function modifyLevelCap (uint level, uint cap) public onlyOwner {
    require (contractStage < 3);
    require (level > 0 && level < contributionCaps.length);
    require (this.balance <= cap && contributionCaps[0] >= cap);
    contributionCaps[level] = cap;
    nextCapTime = 0;
  }
  
   
   
  function modifyAllLevelCaps (uint[] cap, uint time) public onlyOwner {
    require (contractStage < 3);
    require (cap.length == contributionCaps.length-1);
    require (time == 0 || time>block.timestamp);
    if (time == 0) {
      for (uint8 i = 0; i < cap.length; i++) {
        modifyLevelCap(i+1, cap[i]);
      }
    } else {
      nextContributionCaps = contributionCaps;
      nextCapTime = time;
      for (i = 0; i < cap.length; i++) {
        require (contributionCaps[i+1] <= cap[i] && contributionCaps[0] >= cap[i]);
        nextContributionCaps[i+1] = cap[i];
      }
    }
  }
  
   
   
  function modifyMaxContractBalance (uint amount) public onlyOwner {
    require (contractStage < 3);
    require (amount >= contributionMin);
    require (amount >= this.balance);
    contributionCaps[0] = amount;
    nextCapTime = 0;
    for (uint8 i=1; i<contributionCaps.length; i++) {
      if (contributionCaps[i]>amount) contributionCaps[i]=amount;
    }
  }
  
   
  function _checkCap (address addr) internal returns (uint) {
    _checkWhitelistContract(addr);
    var c = whitelist[addr];
    if (!c.authorized) return 0;
    if (nextCapTime>0 && block.timestamp>nextCapTime) {
      contributionCaps = nextContributionCaps;
      nextCapTime = 0;
    }
    if (c.cap<contributionCaps.length) return contributionCaps[c.cap];
    return c.cap; 
  }
  
   
  function _checkWhitelistContract (address addr) internal {
    var c = whitelist[addr];
    if (!c.authorized) {
      var level = whitelistContract.checkMemberLevel(addr);
      if (level == 0 || level >= contributionCaps.length) return;
      c.cap = level;
      c.authorized = true;
    }
  }
  
   
  function checkPoolBalance () view public returns (uint poolCap, uint balance, uint remaining) {
    if (contractStage == 1) {
      remaining = contributionCaps[0].sub(this.balance);
    } else {
      remaining = 0;
    }
    return (contributionCaps[0],this.balance,remaining);
  }
  
   
  function checkContributorBalance (address addr) view public returns (uint balance, uint cap, uint remaining) {
    var c = whitelist[addr];
    if (!c.authorized) {
      cap = whitelistContract.checkMemberLevel(addr);
      if (cap == 0) return (0,0,0);
    } else {
      cap = c.cap;
    }
    balance = c.balance;
    if (contractStage == 1) {
      if (cap<contributionCaps.length) { 
        if (nextCapTime == 0 || nextCapTime > block.timestamp) {
          cap = contributionCaps[cap];
        } else {
          cap = nextContributionCaps[cap];
        }
      }
      remaining = cap.sub(balance);
      if (contributionCaps[0].sub(this.balance) < remaining) remaining = contributionCaps[0].sub(this.balance);
    } else {
      remaining = 0;
    }
    return (balance, cap, remaining);
  }
  
   
  function checkAvailableTokens (address addr, address tokenAddr) view public returns (uint tokenAmount) {
    var c = whitelist[addr];
    var d = distributionMap[tokenAddr];
    for (uint i = c.tokensClaimed[tokenAddr]; i < d.pct.length; i++) {
      tokenAmount = tokenAmount.add(_applyPct(c.balance, d.pct[i]));
    }
    return tokenAmount;
  }
  
   
   
   
  function closeContributions () public onlyOwner {
    require (contractStage == 1);
    contractStage = 2;
  }
  
   
   
  function reopenContributions () public onlyOwner {
    require (contractStage == 2);
    contractStage = 1;
  }
  
   
   
   
   
   
  function setReceiverAddress (address addr) public onlyOwner {
    require (addr != 0x00 && receiverAddress == 0x00);
    require (contractStage < 3);
    receiverAddress = addr;
    addressChangeBlock = block.number;
    ReceiverAddressSet(addr);
  }

   
   
   
   
  function submitPool(uint amountInWei) public onlyOwner noReentrancy {
    require(contractStage < 3);
    require(receiverAddress != 0x00);
    require(block.number >= addressChangeBlock.add(6000));
    require(contributionMin <= amountInWei && amountInWei <= this.balance);
    finalBalance = this.balance;
    require(receiverAddress.call.value(amountInWei).gas(msg.gas.sub(5000))());
    if (this.balance > 0) ethRefundAmount.push(this.balance);
    contractStage = 3;
    PoolSubmitted(receiverAddress, amountInWei);
  }
  
   
   
   
   
  function enableTokenWithdrawals (address tokenAddr, bool notDefault) public onlyOwner noReentrancy {
    require (contractStage == 3);
    if (notDefault) {
      require (activeToken != 0x00);
    } else {
      activeToken = tokenAddr;
    }
    var d = distributionMap[tokenAddr];    
    if (d.pct.length==0) d.token = ERC20(tokenAddr);
    uint amount = d.token.balanceOf(this).sub(d.balanceRemaining);
    require (amount > 0);
    if (feePct > 0) {
      require (d.token.transfer(owner,_applyPct(amount,feePct)));
    }
    amount = d.token.balanceOf(this).sub(d.balanceRemaining);
    d.balanceRemaining = d.token.balanceOf(this);
    d.pct.push(_toPct(amount,finalBalance));
  }
  
   
  function tokenFallback (address from, uint value, bytes data) public {
    ERC223Received (from, value);
  }
  
}