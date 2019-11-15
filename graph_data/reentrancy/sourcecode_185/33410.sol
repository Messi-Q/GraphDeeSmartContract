pragma solidity ^0.4.11;

 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 

 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
 
contract MultiSigWallet {

     
    bool public isMultiSigWallet = false;

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this)) throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner]) throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner]) throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0) throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner]) throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner]) throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed) throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0) throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT) throw;
        if (_required > ownerCount) throw;
        if (_required == 0) throw;
        if (ownerCount == 0) throw;
        _;
    }

     
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
     
     
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0) throw;
            isOwner[_owners[i]] = true;
        }
        isMultiSigWallet = true;
        owners = _owners;
        required = _required;
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)  public ownerExists(msg.sender) transactionExists(transactionId)  notConfirmed(transactionId, msg.sender){
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
     
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     

     
     
    function executeTransaction(uint transactionId)  internal notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if ((pending && !transactions[i].executed) ||
                (executed && transactions[i].executed))
                count += 1;
    }

     
     
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
          if ((pending && !transactions[i].executed) ||
              (executed && transactions[i].executed))
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

contract UpgradeAgent is SafeMath {
  address public owner;
  bool public isUpgradeAgent;
  function upgradeFrom(address _from, uint256 _value) public;
  function setOriginalSupply() public;
}

 
contract BCDCVault is SafeMath {

     
    bool public isBCDCVault = false;

    BCDCToken bcdcToken;

     
    address bcdcMultisig;
     
    uint256 public unlockedBlockForDev;
     
    uint256 public unlockedBlockForFounders;
     
     
    uint256 public numBlocksLockedDev;
     
     
    uint256 public numBlocksLockedFounders;

     
    bool public unlockedAllTokensForDev = false;
     
    bool public unlockedAllTokensForFounders = false;

     
     
    function BCDCVault(address _bcdcMultisig,uint256 _numBlocksLockedForDev,uint256 _numBlocksLockedForFounders) {
         
        if (_bcdcMultisig == 0x0) throw;
         
        bcdcToken = BCDCToken(msg.sender);
         
        bcdcMultisig = _bcdcMultisig;
         
        isBCDCVault = true;
         
        numBlocksLockedDev = _numBlocksLockedForDev;
        numBlocksLockedFounders = _numBlocksLockedForFounders;
         
         
        unlockedBlockForDev = safeAdd(block.number, numBlocksLockedDev);  
         
         
        unlockedBlockForFounders = safeAdd(block.number, numBlocksLockedFounders);  
    }

     
    function unlockForDevelopment() external {
         
        if (block.number < unlockedBlockForDev) throw;
         
        if (unlockedAllTokensForDev) throw;
         
        unlockedAllTokensForDev = true;
         
        uint256 totalBalance = bcdcToken.balanceOf(this);
         
        uint256 developmentTokens = safeDiv(safeMul(totalBalance, 50), 100);
        if (!bcdcToken.transfer(bcdcMultisig, developmentTokens)) throw;
    }

     
    function unlockForFounders() external {
         
        if (block.number < unlockedBlockForFounders) throw;
         
        if (unlockedAllTokensForFounders) throw;
         
        unlockedAllTokensForFounders = true;
         
        if (!bcdcToken.transfer(bcdcMultisig, bcdcToken.balanceOf(this))) throw;
         
        if (!bcdcMultisig.send(this.balance)) throw;
    }

     
    function () payable {
        if (block.number >= unlockedBlockForFounders) throw;
    }

}

 
contract BCDCToken is SafeMath, ERC20 {

     
    bool public isBCDCToken = false;
    bool public upgradeAgentStatus = false;
     
    address public owner;

     
    enum State{PreFunding, Funding, Success, Failure}

     
    string public constant name = "BCDC Token";
    string public constant symbol = "BCDC";
    uint256 public constant decimals = 18;   

     
    mapping (address => uint256) balances;
     
     
    mapping (address => uint256) investment;
    mapping (address => mapping (address => uint256)) allowed;

     
    bool public finalizedCrowdfunding = false;
     
    bool public preallocated = false;
    uint256 public fundingStartBlock;  
    uint256 public fundingEndBlock;  
     

     
     
    uint256 public tokenSaleMax;
     
     
    uint256 public tokenSaleMin;
     
    uint256 public constant maxTokenSupply = 1000000000 ether;
     
    uint256 public constant vaultPercentOfTotal = 5;
     
    uint256 public constant reservedPercentTotal = 25;

     
    address public bcdcMultisig;
     
    address bcdcReserveFund;
     
    BCDCVault public timeVault;

     
    event Refund(address indexed _from, uint256 _value);
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);
    event UpgradeFinalized(address sender, address upgradeAgent);
    event UpgradeAgentSet(address agent);
     
    uint256 tokensPerEther;

     
    bool public halted;

    bool public finalizedUpgrade = false;
    address public upgradeMaster;
    UpgradeAgent public upgradeAgent;
    uint256 public totalUpgraded;


     
     
     
     
     
     
     
    function BCDCToken(address _bcdcMultiSig,
                      address _upgradeMaster,
                      uint256 _fundingStartBlock,
                      uint256 _fundingEndBlock,
                      uint256 _tokenSaleMax,
                      uint256 _tokenSaleMin,
                      uint256 _tokensPerEther,
                      uint256 _numBlocksLockedForDev,
                      uint256 _numBlocksLockedForFounders) {
         
        if (_bcdcMultiSig == 0) throw;
         
        if (_upgradeMaster == 0) throw;

        if (_fundingStartBlock <= block.number) throw;
         
        if (_fundingEndBlock   <= _fundingStartBlock) throw;
         
        if (_tokenSaleMax <= _tokenSaleMin) throw;
         
        if (_tokensPerEther == 0) throw;
         
        isBCDCToken = true;
         
        upgradeMaster = _upgradeMaster;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        tokenSaleMax = _tokenSaleMax;
        tokenSaleMin = _tokenSaleMin;
        tokensPerEther = _tokensPerEther;
         
        timeVault = new BCDCVault(_bcdcMultiSig,_numBlocksLockedForDev,_numBlocksLockedForFounders);
         
        if (!timeVault.isBCDCVault()) throw;
         
        bcdcMultisig = _bcdcMultiSig;
         
        owner = msg.sender;
         
        if (!MultiSigWallet(bcdcMultisig).isMultiSigWallet()) throw;
    }
     
     
    modifier onlyOwner() {
      if (msg.sender != owner) {
        throw;
      }
      _;
    }

     
     
    function transferOwnership(address newOwner) onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

     
     
     
    function setBcdcReserveFund(address _bcdcReserveFund) onlyOwner{
        if (getState() != State.PreFunding) throw;
        if (preallocated) throw;  
        if (_bcdcReserveFund == 0x0) throw;
        bcdcReserveFund = _bcdcReserveFund;
    }

     
     
    function balanceOf(address who) constant returns (uint) {
        return balances[who];
    }

     
     
     
     
    function checkInvestment(address who) constant returns (uint) {
        return investment[who];
    }

     
     
     
    function allowance(address owner, address spender) constant returns (uint) {
        return allowed[owner][spender];
    }

     
     
     
     
     
     
    function transfer(address to, uint value) returns (bool ok) {
        if (getState() != State.Success) throw;  
        uint256 senderBalance = balances[msg.sender];
        if ( senderBalance >= value && value > 0) {
            senderBalance = safeSub(senderBalance, value);
            balances[msg.sender] = senderBalance;
            balances[to] = safeAdd(balances[to], value);
            Transfer(msg.sender, to, value);
            return true;
        }
        return false;
    }

     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint value) returns (bool ok) {
        if (getState() != State.Success) throw;  
        if (balances[from] >= value &&
            allowed[from][msg.sender] >= value &&
            value > 0)
        {
            balances[to] = safeAdd(balances[to], value);
            balances[from] = safeSub(balances[from], value);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
            Transfer(from, to, value);
            return true;
        } else { return false; }
    }

     
     
     
     
    function approve(address spender, uint value) returns (bool ok) {
        if (getState() != State.Success) throw;  
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
    function() payable stopIfHalted external {
         
        if (getState() != State.Funding) throw;

         
        if (msg.value == 0) throw;

         
        uint256 createdTokens = safeMul(msg.value, tokensPerEther);

         
        if (safeAdd(createdTokens, totalSupply) > tokenSaleMax) throw;

         
        assignTokens(msg.sender, createdTokens);

         
        investment[msg.sender] = safeAdd(investment[msg.sender], msg.value);
    }

     
     
    function preAllocation() onlyOwner stopIfHalted external {
         
        if (getState() != State.PreFunding) throw;
         
        if (bcdcReserveFund == 0x0) throw;
         
        if (preallocated) throw;
        preallocated = true;
         
        uint256 projectTokens = safeDiv(safeMul(maxTokenSupply, reservedPercentTotal), 100);
         
         
        balances[bcdcReserveFund] = projectTokens;
         
        Transfer(0, bcdcReserveFund, projectTokens);
    }

     
     
    function earlyInvestment(address earlyInvestor, uint256 assignedTokens) onlyOwner stopIfHalted external {
         
        if (getState() != State.PreFunding && getState() != State.Funding) throw;
         
        if (earlyInvestor == 0x0) throw;
         
        if (assignedTokens == 0 ) throw;

         
        assignTokens(earlyInvestor, assignedTokens);

         
         
         
    }

     
     
    function assignTokens(address investor, uint256 tokens) internal {
         
        totalSupply = safeAdd(totalSupply, tokens);

         
        balances[investor] = safeAdd(balances[investor], tokens);

         
        Transfer(0, investor, tokens);
    }

     
     
    function finalizeCrowdfunding() stopIfHalted external {
         
        if (getState() != State.Success) throw;  
        if (finalizedCrowdfunding) throw;  

         
        finalizedCrowdfunding = true;

         
         
        uint256 unsoldTokens = safeSub(tokenSaleMax, totalSupply);

         
        uint256 vaultTokens = safeDiv(safeMul(maxTokenSupply, vaultPercentOfTotal), 100);
        totalSupply = safeAdd(totalSupply, vaultTokens);
        balances[timeVault] = safeAdd(balances[timeVault], vaultTokens);
        Transfer(0, timeVault, vaultTokens);

         
        if(unsoldTokens > 0) {
            totalSupply = safeAdd(totalSupply, unsoldTokens);
             
            balances[bcdcMultisig] = safeAdd(balances[bcdcMultisig], unsoldTokens); 
            Transfer(0, bcdcMultisig, unsoldTokens);
        }

         
        uint256 preallocatedTokens = safeDiv(safeMul(maxTokenSupply, reservedPercentTotal), 100);
         
        totalSupply = safeAdd(totalSupply, preallocatedTokens);
         
         
        uint256 rewardTokens = safeDiv(safeMul(maxTokenSupply, reservedPercentTotal), 100);
        balances[bcdcMultisig] = safeAdd(balances[bcdcMultisig], rewardTokens); 
        totalSupply = safeAdd(totalSupply, rewardTokens);

         
        if (totalSupply > maxTokenSupply) throw;
         
        if (!bcdcMultisig.send(this.balance)) throw;
    }

     
     
    function refund() external {
         
        if (getState() != State.Failure) throw;

        uint256 bcdcValue = balances[msg.sender];
        if (bcdcValue == 0) throw;
        balances[msg.sender] = 0;
        totalSupply = safeSub(totalSupply, bcdcValue);

        uint256 ethValue = investment[msg.sender];
        investment[msg.sender] = 0;
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }

     
     
    function getState() public constant returns (State){
      if (block.number < fundingStartBlock) return State.PreFunding;
      else if (block.number <= fundingEndBlock && totalSupply < tokenSaleMax) return State.Funding;
      else if (totalSupply >= tokenSaleMin || upgradeAgentStatus) return State.Success;
      else return State.Failure;
    }

     

     
     
     
    function upgrade(uint256 value) external {
        if (!upgradeAgentStatus) throw;
        if (upgradeAgent.owner() == 0x0) throw;
        if (finalizedUpgrade) throw;  

         
        if (value == 0) throw;
        if (value > balances[msg.sender]) throw;

         
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
     
     
     
    function setUpgradeAgent(address agent) external {
        if (getState() != State.Success) throw;  
        if (agent == 0x0) throw;  
        if (msg.sender != upgradeMaster) throw;  
        upgradeAgent = UpgradeAgent(agent);
        if (!upgradeAgent.isUpgradeAgent()) throw;
         
        upgradeAgentStatus = true;
        upgradeAgent.setOriginalSupply();
        UpgradeAgentSet(upgradeAgent);
    }

     
     
     
     
    function setUpgradeMaster(address master) external {
        if (getState() != State.Success) throw;  
        if (master == 0x0) throw;
        if (msg.sender != upgradeMaster) throw;  
        upgradeMaster = master;
    }

     

     
    modifier stopIfHalted {
      if(halted) throw;
      _;
    }

     
    modifier runIfHalted{
      if(!halted) throw;
      _;
    }

     
    function halt() external onlyOwner{
      halted = true;
    }

     
    function unhalt() external onlyOwner{
      halted = false;
    }

     
     
     
     
     
    function reserveTokenClaim(address claimAddress,uint256 token) onlyBcdcReserve returns (bool ok){
       
      if ( bcdcReserveFund == 0x0) throw;
      uint256 senderBalance = balances[msg.sender];
      if(senderBalance >= token && token>0){
        senderBalance = safeSub(senderBalance, token);
        balances[msg.sender] = senderBalance;
        balances[claimAddress] = safeAdd(balances[claimAddress], token);
        Transfer(msg.sender, claimAddress, token);
        return true;
      }
      return false;
    }

     
	   
  	function backTokenForRewards(uint256 tokens) external{
  		 
  		if(balances[msg.sender] < tokens && tokens <= 0) throw;

  		 
  		balances[msg.sender] = safeSub(balances[msg.sender], tokens);

  		 
  		balances[bcdcReserveFund] = safeAdd(balances[bcdcReserveFund], tokens);
  		Transfer(msg.sender, bcdcReserveFund, tokens);
  	}

     
     
    modifier onlyBcdcReserve() {
      if (msg.sender != bcdcReserveFund) {
        throw;
      }
      _;
    }
}