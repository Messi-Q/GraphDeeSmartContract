 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.15;
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
        m_numOwners = _owners.length;
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[1 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 1 + i;
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

    function isOwner(address _addr) constant returns (bool) {
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
            } else {
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



 
contract multisig {

	 

     
     
    event Deposit(address _from, uint value);
     
    event SingleTransact(address owner, uint value, address to, bytes data);
     
    event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data);
     
    event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);
    
     
    
     
    function changeOwner(address _from, address _to) external;
    function execute(address _to, uint _value, bytes _data) external returns (bytes32);
    function confirm(bytes32 _h) returns (bool);
}

 
 
 
contract Wallet is multisig, multiowned {



	 

     
    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

     

     
    function Wallet(address[] _owners, uint _required)
            multiowned(_owners, _required)  {
    }
    
    
     
    function() payable{
         
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }
    
     
     
     
     
    function execute(address _to, uint _value, bytes _data) external onlyowner returns (bytes32 _r) {
         
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
            var x= m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data);
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