pragma solidity ^0.4.0;
 

contract Lockable {
    uint public numOfCurrentEpoch;
    uint public creationTime;
    uint public constant UNLOCKED_TIME = 25 days;
    uint public constant LOCKED_TIME = 5 days;
    uint public constant EPOCH_LENGTH = 30 days;
    bool public lock;
    bool public tokenSwapLock;

    event Locked();
    event Unlocked();

     
     
    modifier isTokenSwapOn {
        if (tokenSwapLock) throw;
        _;
    }

     
     
     
    modifier isNewEpoch {
        if (numOfCurrentEpoch * EPOCH_LENGTH + creationTime < now ) {
            numOfCurrentEpoch = (now - creationTime) / EPOCH_LENGTH + 1;
        }
        _;
    }

     
     
     
    modifier checkLock {
        if ((creationTime + numOfCurrentEpoch * UNLOCKED_TIME) +
        (numOfCurrentEpoch - 1) * LOCKED_TIME < now) {
             
            if (lock) throw;

            lock = true;
            Locked();
            return;
        }
        else {
             
             
            if (lock) {
                lock = false;
                Unlocked();
            }
        }
        _;
    }

    function Lockable() {
        creationTime = now;
        numOfCurrentEpoch = 1;
        tokenSwapLock = true;
    }
}


contract ERC20 {
    function totalSupply() constant returns (uint);
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is ERC20, Lockable {

  mapping( address => uint ) _balances;
  mapping( address => mapping( address => uint ) ) _approvals;
  uint _supply;
  address public walletAddress;

  event TokenMint(address newTokenHolder, uint amountOfTokens);
  event TokenSwapOver();

  modifier onlyFromWallet {
      if (msg.sender != walletAddress) throw;
      _;
  }

  function Token( uint initial_balance, address wallet) {
    _balances[msg.sender] = initial_balance;
    _supply = initial_balance;
    walletAddress = wallet;
  }

  function totalSupply() constant returns (uint supply) {
    return _supply;
  }

  function balanceOf( address who ) constant returns (uint value) {
    return _balances[who];
  }

  function allowance(address owner, address spender) constant returns (uint _allowance) {
    return _approvals[owner][spender];
  }

   
  function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a && a + b >= b);
  }

  function transfer( address to, uint value) isTokenSwapOn isNewEpoch  checkLock
    returns (bool ok) {

    if( _balances[msg.sender] < value ) {
        throw;
    }
    if( !safeToAdd(_balances[to], value) ) {
        throw;
    }

    _balances[msg.sender] -= value;
    _balances[to] += value;
    Transfer( msg.sender, to, value );
    return true;
  }

  function transferFrom( address from, address to, uint value) isTokenSwapOn isNewEpoch checkLock returns (bool ok) {
     
    if( _balances[from] < value ) {
        throw;
    }
     
    if( _approvals[from][msg.sender] < value ) {
        throw;
    }
    if( !safeToAdd(_balances[to], value) ) {
        throw;
    }
     
    _approvals[from][msg.sender] -= value;
    _balances[from] -= value;
    _balances[to] += value;
    Transfer( from, to, value );
    return true;
  }

  function approve(address spender, uint value) isTokenSwapOn isNewEpoch checkLock returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    Approval( msg.sender, spender, value );
    return true;
  }

   
   
  function currentSwapRate() constant returns(uint) {
      if (creationTime + 1 weeks > now) {
          return 130;
      }
      else if (creationTime + 2 weeks > now) {
          return 120;
      }
      else if (creationTime + 4 weeks > now) {
          return 100;
      }
      else {
          return 0;
      }
  }

   
   
   
   
  function mintTokens(address newTokenHolder, uint etherAmount) external onlyFromWallet {

        uint tokensAmount = currentSwapRate() * etherAmount;
        if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw;
        if(!safeToAdd(_supply,tokensAmount)) throw;

        _balances[newTokenHolder] += tokensAmount;
        _supply += tokensAmount;

        TokenMint(newTokenHolder, tokensAmount);
  }

   
   
  function disableTokenSwapLock() external onlyFromWallet {
        tokenSwapLock = false;
        TokenSwapOver();
  }
}

pragma solidity ^0.4.0;

 

contract multiowned {

	 

     
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

	 

     
     
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
     
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
     
    event RequirementChanged(uint newRequirement);

	 

     
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }
     
     
     
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

	 

     
     
    function multiowned(address[] _owners, uint _required) {
        m_numOwners = _owners.length + 1;
        m_owners[1] = uint(msg.sender);
        m_ownerIndex[uint(msg.sender)] = 1;
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[2 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 2 + i;
        }
        m_required = _required;
    }

     
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) return;
        uint ownerIndexBit = 2**ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }

     
    function changeOwner(address _from, address _to) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }

    function addOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_owner)) return;

        clearPending();
        if (m_numOwners >= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners >= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner);
    }

    function removeOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        if (m_required > m_numOwners - 1) return;

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners();  
        OwnerRemoved(_owner);
    }

    function changeRequirement(uint _newRequired) onlymanyowners(sha3(msg.data)) external {
        if (_newRequired > m_numOwners) return;
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

     
    function getOwner(uint ownerIndex) external constant returns (address) {
        return address(m_owners[ownerIndex + 1]);
    }

    function isOwner(address _addr) returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

         
        if (ownerIndex == 0) return false;

         
        uint ownerIndexBit = 2**ownerIndex;
        return !(pending.ownersDone & ownerIndexBit == 0);
    }

     

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
         
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) return;

        var pending = m_pending[_operation];
         
        if (pending.yetNeeded == 0) {
             
            pending.yetNeeded = m_required;
             
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
         
        uint ownerIndexBit = 2**ownerIndex;
         
        if (pending.ownersDone & ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
             
            if (pending.yetNeeded <= 1) {
                 
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            }
            else
            {
                 
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            while (free < m_numOwners && m_owners[free] != 0) free++;
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            if (m_pendingIndex[i] != 0)
                delete m_pending[m_pendingIndex[i]];
        delete m_pendingIndex;
    }

   	 

     
    uint public m_required;
     
    uint public m_numOwners;

     
    uint[256] m_owners;
    uint constant c_maxOwners = 250;
     
    mapping(uint => uint) m_ownerIndex;
     
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}

 
 
 
contract daylimit is multiowned {

	 

     
    modifier limitedDaily(uint _value) {
        if (underLimit(_value))
            _;
    }

	 

     
    function daylimit(uint _limit) {
        m_dailyLimit = _limit;
        m_lastDay = today();
    }
     
    function setDailyLimit(uint _newLimit) onlymanyowners(sha3(msg.data)) external {
        m_dailyLimit = _newLimit;
    }
     
    function resetSpentToday() onlymanyowners(sha3(msg.data)) external {
        m_spentToday = 0;
    }

     

     
     
    function underLimit(uint _value) internal onlyowner returns (bool) {
         
        if (today() > m_lastDay) {
            m_spentToday = 0;
            m_lastDay = today();
        }
         
         
        if (m_spentToday + _value >= m_spentToday && m_spentToday + _value <= m_dailyLimit) {
            m_spentToday += _value;
            return true;
        }
        return false;
    }
     
    function today() private constant returns (uint) { return now / 1 days; }

	 

    uint public m_dailyLimit;
    uint public m_spentToday;
    uint public m_lastDay;
}

 
contract multisig {

	 

     
     
    event Deposit(address _from, uint value);
     
    event SingleTransact(address owner, uint value, address to, bytes data);
     
    event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data);
     
    event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);

     

     
    function changeOwner(address _from, address _to) external;
    function execute(address _to, uint _value, bytes _data) external returns (bytes32);
    function confirm(bytes32 _h) returns (bool);
}

contract tokenswap is multisig, multiowned {
    Token public tokenCtr;
    bool public tokenSwap;
    uint public constant SWAP_LENGTH = 4  weeks;
    uint public constant MAX_ETH = 700000 ether;
    uint public amountRaised;

    modifier isZeroValue {
        if (msg.value == 0) throw;
        _;
    }

    modifier isOverCap {
	if (amountRaised + msg.value > MAX_ETH) throw;
        _;
    }

    modifier isSwapStopped {
        if (!tokenSwap) throw;
        _;
    }

    modifier areConditionsSatisfied {
	 
	if (tokenCtr.creationTime() + SWAP_LENGTH < now) {
            tokenCtr.disableTokenSwapLock();
            tokenSwap = false;
        }
        else {
            _;
	         
            if (amountRaised == MAX_ETH) {
                tokenCtr.disableTokenSwapLock();
                tokenSwap = false;
            }
        }
    }

    function safeToAdd(uint a, uint b) internal returns (bool) {
      return (a + b >= a && a + b >= b);
    }

    function startTokenSwap() onlyowner {
        tokenSwap = true;
    }

    function stopTokenSwap() onlyowner {
        tokenSwap = false;
    }

    function setTokenContract(address newTokenContractAddr) onlyowner {
        if (newTokenContractAddr == address(0x0)) throw;
         
        if (tokenCtr != address(0x0)) throw;

        tokenCtr = Token(newTokenContractAddr);
    }

    function buyTokens(address _beneficiary)
    payable
    isZeroValue
    isOverCap
    isSwapStopped
    areConditionsSatisfied {
        Deposit(msg.sender, msg.value);
        tokenCtr.mintTokens(_beneficiary, msg.value);
        if (!safeToAdd(amountRaised, msg.value)) throw;
        amountRaised += msg.value;
    }
}

 
 
 
contract Wallet is multisig, multiowned, daylimit, tokenswap {

	 

     
    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

     

     
     
    function Wallet(address[] _owners, uint _required, uint _daylimit)
            multiowned(_owners, _required) daylimit(_daylimit) {
    }

     
    function kill(address _to) onlymanyowners(sha3(msg.data)) external {
         
         
         
         
        if (tokenCtr.tokenSwapLock()) throw;

        suicide(_to);
    }

     
    function()
    payable {
        buyTokens(msg.sender);
    }

     
     
     
     
    function execute(address _to, uint _value, bytes _data) external onlyowner returns (bytes32 _r) {
         
         
         
        if (_to == address(tokenCtr)) throw;

         
        if (underLimit(_value)) {
            SingleTransact(msg.sender, _value, _to, _data);
             
            if(!_to.call.value(_value)(_data))
            return 0;
        }
         
        _r = sha3(msg.data, block.number);
        if (!confirm(_r) && m_txs[_r].to == 0) {
            m_txs[_r].to = _to;
            m_txs[_r].value = _value;
            m_txs[_r].data = _data;
            ConfirmationNeeded(_r, msg.sender, _value, _to, _data);
        }
    }

     
     
    function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
        if (m_txs[_h].to != 0) {
            if(!m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data))
            MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to, m_txs[_h].data);
            delete m_txs[_h];
            return true;
        }
    }

     

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            delete m_txs[m_pendingIndex[i]];
        super.clearPending();
    }

	 

     
    mapping (bytes32 => Transaction) m_txs;
}