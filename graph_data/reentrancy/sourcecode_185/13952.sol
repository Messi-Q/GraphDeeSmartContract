pragma solidity ^0.4.23;

 

 
 
interface IRegistry {
    function owner() external view returns (address _addr);
    function addressOf(bytes32 _name) external view returns (address _addr);
}

contract UsingRegistry {
    IRegistry private registry;

    modifier fromOwner(){
        require(msg.sender == getOwner());
        _;
    }

    constructor(address _registry)
        public
    {
        require(_registry != 0);
        registry = IRegistry(_registry);
    }

    function addressOf(bytes32 _name)
        internal
        view
        returns(address _addr)
    {
        return registry.addressOf(_name);
    }

    function getOwner()
        public
        view
        returns (address _addr)
    {
        return registry.owner();
    }

    function getRegistry()
        public
        view
        returns (IRegistry _addr)
    {
        return registry;
    }
}


 
contract UsingAdmin is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromAdmin(){
        require(msg.sender == getAdmin());
        _;
    }
    
    function getAdmin()
        public
        constant
        returns (address _addr)
    {
        return addressOf("ADMIN");
    }
}

 
 
interface ITreasury {
    function issueDividend() external returns (uint _profits);
    function profitsSendable() external view returns (uint _profits);
}

contract UsingTreasury is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromTreasury(){
        require(msg.sender == address(getTreasury()));
        _;
    }
    
    function getTreasury()
        public
        view
        returns (ITreasury)
    {
        return ITreasury(addressOf("TREASURY"));
    }
}


 
contract Ledger {
    uint public total;       

    struct Entry {           
        uint balance;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

     
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


     
     
     

    function add(address _address, uint _amt)
        fromOwner
        public
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

         
        if (entry.balance == 0) {
            entry.next = entries[0x0].next;
            entries[entries[0x0].next].prev = _address;
            entries[0x0].next = _address;
        }
         
        total += _amt;
        entry.balance += _amt;
    }

    function subtract(address _address, uint _amt)
        fromOwner
        public
        returns (uint _amtRemoved)
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

        uint _maxAmt = entry.balance;
        if (_maxAmt == 0) return;
        
        if (_amt >= _maxAmt) {
             
            total -= _maxAmt;
            entries[entry.prev].next = entry.next;
            entries[entry.next].prev = entry.prev;
            delete entries[_address];
            return _maxAmt;
        } else {
             
            total -= _amt;
            entry.balance -= _amt;
            return _amt;
        }
    }


     
     
     

    function size()
        public
        view
        returns (uint _size)
    {
         
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function balanceOf(address _address)
        public
        view
        returns (uint _balance)
    {
        return entries[_address].balance;
    }

    function balances()
        public
        view
        returns (address[] _addresses, uint[] _balances)
    {
         
        uint _size = size();
        _addresses = new address[](_size);
        _balances = new uint[](_size);
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _balances[_i] = entries[_curEntry.next].balance;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return (_addresses, _balances);
    }
}


 
contract AddressSet {
    
    struct Entry {   
        bool exists;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

     
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


     
     
     

    function add(address _address)
        fromOwner
        public
        returns (bool _didCreate)
    {
         
        if (_address == address(0)) return;
        Entry storage entry = entries[_address];
         
        if (entry.exists) return;
        else entry.exists = true;

         
         
         
         
        Entry storage HEAD = entries[0x0];
        entry.next = HEAD.next;
        entries[HEAD.next].prev = _address;
        HEAD.next = _address;
        return true;
    }

    function remove(address _address)
        fromOwner
        public
        returns (bool _didExist)
    {
         
        if (_address == address(0)) return;
        Entry storage entry = entries[_address];
         
        if (!entry.exists) return;

         
         
         
         
        entries[entry.prev].next = entry.next;
        entries[entry.next].prev = entry.prev;
        delete entries[_address];
        return true;
    }


     
     
     

    function size()
        public
        view
        returns (uint _size)
    {
         
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function has(address _address)
        public
        view
        returns (bool _exists)
    {
        return entries[_address].exists;
    }

    function addresses()
        public
        view
        returns (address[] _addresses)
    {
         
        uint _size = size();
        _addresses = new address[](_size);
         
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return _addresses;
    }
}

 
contract Bankrollable is
    UsingTreasury
{   
     
    uint public profitsSent;
     
    Ledger public ledger;
     
    uint public bankroll;
     
    AddressSet public whitelist;

    modifier fromWhitelistOwner(){
        require(msg.sender == getWhitelistOwner());
        _;
    }

    event BankrollAdded(uint time, address indexed bankroller, uint amount, uint bankroll);
    event BankrollRemoved(uint time, address indexed bankroller, uint amount, uint bankroll);
    event ProfitsSent(uint time, address indexed treasury, uint amount);
    event AddedToWhitelist(uint time, address indexed addr, address indexed wlOwner);
    event RemovedFromWhitelist(uint time, address indexed addr, address indexed wlOwner);

     
    constructor(address _registry)
        UsingTreasury(_registry)
        public
    {
        ledger = new Ledger(this);
        whitelist = new AddressSet(this);
    }


     
     
         

    function addToWhitelist(address _addr)
        fromWhitelistOwner
        public
    {
        bool _didAdd = whitelist.add(_addr);
        if (_didAdd) emit AddedToWhitelist(now, _addr, msg.sender);
    }

    function removeFromWhitelist(address _addr)
        fromWhitelistOwner
        public
    {
        bool _didRemove = whitelist.remove(_addr);
        if (_didRemove) emit RemovedFromWhitelist(now, _addr, msg.sender);
    }

     
     
     

     
    function () public payable {}

     
    function addBankroll()
        public
        payable 
    {
        require(whitelist.size()==0 || whitelist.has(msg.sender));
        ledger.add(msg.sender, msg.value);
        bankroll = ledger.total();
        emit BankrollAdded(now, msg.sender, msg.value, bankroll);
    }

     
    function removeBankroll(uint _amount, string _callbackFn)
        public
        returns (uint _recalled)
    {
         
        address _bankroller = msg.sender;
        uint _collateral = getCollateral();
        uint _balance = address(this).balance;
        uint _available = _balance > _collateral ? _balance - _collateral : 0;
        if (_amount > _available) _amount = _available;

         
        _amount = ledger.subtract(_bankroller, _amount);
        bankroll = ledger.total();
        if (_amount == 0) return;

        bytes4 _sig = bytes4(keccak256(_callbackFn));
        require(_bankroller.call.value(_amount)(_sig));
        emit BankrollRemoved(now, _bankroller, _amount, bankroll);
        return _amount;
    }

     
    function sendProfits()
        public
        returns (uint _profits)
    {
        int _p = profits();
        if (_p <= 0) return;
        _profits = uint(_p);
        profitsSent += _profits;
         
        address _tr = getTreasury();
        require(_tr.call.value(_profits)());
        emit ProfitsSent(now, _tr, _profits);
    }


     
     
     

     
    function getCollateral()
        public
        view
        returns (uint _amount);

     
    function getWhitelistOwner()
        public
        view
        returns (address _addr);

     
    function profits()
        public
        view
        returns (int _profits)
    {
        int _balance = int(address(this).balance);
        int _threshold = int(bankroll + getCollateral());
        return _balance - _threshold;
    }

     
    function profitsTotal()
        public
        view
        returns (int _profits)
    {
        return int(profitsSent) + profits();
    }

     
     
     
     
    function bankrollAvailable()
        public
        view
        returns (uint _amount)
    {
        uint _balance = address(this).balance;
        uint _bankroll = bankroll;
        uint _collat = getCollateral();
         
        if (_balance <= _collat) return 0;
         
        else if (_balance < _collat + _bankroll) return _balance - _collat;
         
        else return _bankroll;
    }

    function bankrolledBy(address _addr)
        public
        view
        returns (uint _amount)
    {
        return ledger.balanceOf(_addr);
    }

    function bankrollerTable()
        public
        view
        returns (address[], uint[])
    {
        return ledger.balances();
    }
}

contract VideoPokerUtils {
    uint constant HAND_UNDEFINED = 0;
    uint constant HAND_RF = 1;
    uint constant HAND_SF = 2;
    uint constant HAND_FK = 3;
    uint constant HAND_FH = 4;
    uint constant HAND_FL = 5;
    uint constant HAND_ST = 6;
    uint constant HAND_TK = 7;
    uint constant HAND_TP = 8;
    uint constant HAND_JB = 9;
    uint constant HAND_HC = 10;
    uint constant HAND_NOT_COMPUTABLE = 11;

     
     
     

     
     
    function getHand(uint256 _hash)
        public
        pure
        returns (uint32)
    {
         
        return uint32(getCardsFromHash(_hash, 5, 0));
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function drawToHand(uint256 _hash, uint32 _hand, uint _draws)
        public
        pure
        returns (uint32)
    {
         
        assert(_draws <= 31);
        assert(_hand != 0 || _draws == 31);
         
        if (_draws == 0) return _hand;
        if (_draws == 31) return uint32(getCardsFromHash(_hash, 5, handToBitmap(_hand)));

         
        uint _newMask;
        for (uint _i=0; _i<5; _i++) {
            if (_draws & 2**_i == 0) continue;
            _newMask |= 63 * (2**(6*_i));
        }
         
         
        uint _discardMask = ~_newMask & (2**31-1);

         
        uint _newHand = getCardsFromHash(_hash, 5, handToBitmap(_hand));
        _newHand &= _newMask;
        _newHand |= _hand & _discardMask;
        return uint32(_newHand);
    }

     
     
    function getHandRank(uint32 _hand)
        public
        pure
        returns (uint)
    {
        if (_hand == 0) return HAND_NOT_COMPUTABLE;

        uint _card;
        uint[] memory _valCounts = new uint[](13);
        uint[] memory _suitCounts = new uint[](5);
        uint _pairVal;
        uint _minNonAce = 100;
        uint _maxNonAce = 0;
        uint _numPairs;
        uint _maxSet;
        bool _hasFlush;
        bool _hasAce;

         
         
         
         
        uint _i;
        uint _val;
        for (_i=0; _i<5; _i++) {
            _card = readFromCards(_hand, _i);
            if (_card > 51) return HAND_NOT_COMPUTABLE;
            
             
            _val = _card % 13;
            _valCounts[_val]++;
            _suitCounts[_card/13]++;
            if (_suitCounts[_card/13] == 5) _hasFlush = true;
            
             
            if (_val == 0) {
                _hasAce = true;
            } else {
                if (_val < _minNonAce) _minNonAce = _val;
                if (_val > _maxNonAce) _maxNonAce = _val;
            }

             
            if (_valCounts[_val] == 2) {
                if (_numPairs==0) _pairVal = _val;
                _numPairs++;
            } else if (_valCounts[_val] == 3) {
                _maxSet = 3;
            } else if (_valCounts[_val] == 4) {
                _maxSet = 4;
            }
        }

        if (_numPairs > 0){
             
            if (_maxSet==4) return HAND_FK;
             
            if (_maxSet==3 && _numPairs==2) return HAND_FH;
             
            if (_maxSet==3) return HAND_TK;
             
            if (_numPairs==2) return HAND_TP;
             
            if (_numPairs == 1 && (_pairVal >= 10 || _pairVal==0)) return HAND_JB;
             
            return HAND_HC;
        }

         
        bool _hasStraight = _hasAce
             
            ? _maxNonAce == 4 || _minNonAce == 9
             
            : _maxNonAce - _minNonAce == 4;
        
         
        if (_hasStraight && _hasFlush && _minNonAce==9) return HAND_RF;
        if (_hasStraight && _hasFlush) return HAND_SF;
        if (_hasFlush) return HAND_FL;
        if (_hasStraight) return HAND_ST;
        return HAND_HC;
    }

     
    function handToCards(uint32 _hand)
        public
        pure
        returns (uint8[5] _cards)
    {
        uint32 _mask;
        for (uint _i=0; _i<5; _i++){
            _mask = uint32(63 * 2**(6*_i));
            _cards[_i] = uint8((_hand & _mask) / (2**(6*_i)));
        }
    }



     
     
     

    function readFromCards(uint _cards, uint _index)
        internal
        pure
        returns (uint)
    {
        uint _offset = 2**(6*_index);
        uint _oneBits = 2**6 - 1;
        return (_cards & (_oneBits * _offset)) / _offset;
    }

     
    function handToBitmap(uint32 _hand)
        internal
        pure
        returns (uint _bitmap)
    {
        if (_hand == 0) return 0;
        uint _mask;
        uint _card;
        for (uint _i=0; _i<5; _i++){
            _mask = 63 * 2**(6*_i);
            _card = (_hand & _mask) / (2**(6*_i));
            _bitmap |= 2**_card;
        }
    }

     
     
    function getCardsFromHash(uint256 _hash, uint _numCards, uint _usedBitmap)
        internal
        pure
        returns (uint _cards)
    {
         
        if (_numCards == 0) return;

        uint _cardIdx = 0;                 
        uint _card;                        
        uint _usedMask;                    

        while (true) {
            _card = _hash % 52;            
            _usedMask = 2**_card;          

             
             
            if (_usedBitmap & _usedMask == 0) {
                _cards |= (_card * 2**(_cardIdx*6));
                _usedBitmap |= _usedMask;
                _cardIdx++;
                if (_cardIdx == _numCards) return _cards;
            }

             
            _hash = uint256(keccak256(_hash));
        }
    }
}

contract VideoPoker is
    VideoPokerUtils,
    Bankrollable,
    UsingAdmin
{
     
    struct Game {
         
        uint32 userId;
        uint64 bet;          
        uint16 payTableId;   
        uint32 iBlock;       
        uint32 iHand;        
        uint8 draws;         
        uint32 dBlock;       
        uint32 dHand;        
        uint8 handRank;      
    }

     
     
     
    struct Vars {
         
        uint32 curId;                
        uint64 totalWageredGwei;     
        uint32 curUserId;            
        uint128 empty1;              
                                     
         
        uint64 totalWonGwei;         
        uint88 totalCredits;         
        uint8 empty2;                
    }

    struct Settings {
        uint64 minBet;
        uint64 maxBet;
        uint16 curPayTableId;
        uint16 numPayTables;
        uint32 lastDayAdded;
    }

    Settings settings;
    Vars vars;

     
    mapping(uint32 => Game) public games;
    
     
    mapping(address => uint) public credits;

     
     
     
     
    mapping (address => uint32) public userIds;
    mapping (uint32 => address) public userAddresses;

     
     
    mapping(uint16=>uint16[12]) payTables;

     
    uint8 public constant version = 2;
    uint8 constant WARN_IHAND_TIMEOUT = 1;  
    uint8 constant WARN_DHAND_TIMEOUT = 2;  
    uint8 constant WARN_BOTH_TIMEOUT = 3;   
    
     
    event Created(uint time);
    event PayTableAdded(uint time, address admin, uint payTableId);
    event SettingsChanged(uint time, address admin);
     
    event BetSuccess(uint time, address indexed user, uint32 indexed id, uint bet, uint payTableId);
    event BetFailure(uint time, address indexed user, uint bet, string msg);
    event DrawSuccess(uint time, address indexed user, uint32 indexed id, uint32 iHand, uint8 draws, uint8 warnCode);
    event DrawFailure(uint time, address indexed user, uint32 indexed id, uint8 draws, string msg);
    event FinalizeSuccess(uint time, address indexed user, uint32 indexed id, uint32 dHand, uint8 handRank, uint payout, uint8 warnCode);
    event FinalizeFailure(uint time, address indexed user, uint32 indexed id, string msg);
     
    event CreditsAdded(uint time, address indexed user, uint32 indexed id, uint amount);
    event CreditsUsed(uint time, address indexed user, uint32 indexed id, uint amount);
    event CreditsCashedout(uint time, address indexed user, uint amount);
        
    constructor(address _registry)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        public
    {
         
        _addPayTable(800, 50, 25, 9, 6, 4, 3, 2, 1);
         
         
         
         
        vars.curId = 293;
        vars.totalWageredGwei =2864600000;
        vars.curUserId = 38;
        vars.totalWonGwei = 2450400000;

         
        settings.minBet = .001 ether;
        settings.maxBet = .375 ether;
        emit Created(now);
    }
    
    
     
     
     
    
     
    function changeSettings(uint64 _minBet, uint64 _maxBet, uint8 _payTableId)
        public
        fromAdmin
    {
        require(_maxBet <= .375 ether);
        require(_payTableId < settings.numPayTables);
        settings.minBet = _minBet;
        settings.maxBet = _maxBet;
        settings.curPayTableId = _payTableId;
        emit SettingsChanged(now, msg.sender);
    }
    
     
    function addPayTable(
        uint16 _rf, uint16 _sf, uint16 _fk, uint16 _fh,
        uint16 _fl, uint16 _st, uint16 _tk, uint16 _tp, uint16 _jb
    )
        public
        fromAdmin
    {
        uint32 _today = uint32(block.timestamp / 1 days);
        require(settings.lastDayAdded < _today);
        settings.lastDayAdded = _today;
        _addPayTable(_rf, _sf, _fk, _fh, _fl, _st, _tk, _tp, _jb);
        emit PayTableAdded(now, msg.sender, settings.numPayTables-1);
    }
    

     
     
     

     
    function addCredits()
        public
        payable
    {
        _creditUser(msg.sender, msg.value, 0);
    }

     
    function cashOut(uint _amt)
        public
    {
        _uncreditUser(msg.sender, _amt);
    }

     
     
     
     
     
     
     
     
    function bet()
        public
        payable
    {
        uint _bet = msg.value;
        if (_bet > settings.maxBet)
            return _betFailure("Bet too large.", _bet, true);
        if (_bet < settings.minBet)
            return _betFailure("Bet too small.", _bet, true);
        if (_bet > curMaxBet())
            return _betFailure("The bankroll is too low.", _bet, true);

         
        uint32 _id = _createNewGame(uint64(_bet));
        emit BetSuccess(now, msg.sender, _id, _bet, settings.curPayTableId);
    }

     
     
     
     
     
     
     
     
     
     
    function betWithCredits(uint64 _bet)
        public
    {
        if (_bet > settings.maxBet)
            return _betFailure("Bet too large.", _bet, false);
        if (_bet < settings.minBet)
            return _betFailure("Bet too small.", _bet, false);
        if (_bet > curMaxBet())
            return _betFailure("The bankroll is too low.", _bet, false);
        if (_bet > credits[msg.sender])
            return _betFailure("Insufficient credits", _bet, false);

        uint32 _id = _createNewGame(uint64(_bet));
        vars.totalCredits -= uint88(_bet);
        credits[msg.sender] -= _bet;
        emit CreditsUsed(now, msg.sender, _id, _bet);
        emit BetSuccess(now, msg.sender, _id, _bet, settings.curPayTableId);
    }

    function betFromGame(uint32 _id, bytes32 _hashCheck)
        public
    {
        bool _didFinalize = finalize(_id, _hashCheck);
        uint64 _bet = games[_id].bet;
        if (!_didFinalize)
            return _betFailure("Failed to finalize prior game.", _bet, false);
        betWithCredits(_bet);
    }

         
        function _betFailure(string _msg, uint _bet, bool _doRefund)
            private
        {
            if (_doRefund) require(msg.sender.call.value(_bet)());
            emit BetFailure(now, msg.sender, _bet, _msg);
        }
        

     
     
     
     
     
     
     
     
     
     
     
    function draw(uint32 _id, uint8 _draws, bytes32 _hashCheck)
        public
    {
        Game storage _game = games[_id];
        address _user = userAddresses[_game.userId];
        if (_game.iBlock == 0)
            return _drawFailure(_id, _draws, "Invalid game Id.");
        if (_user != msg.sender)
            return _drawFailure(_id, _draws, "This is not your game.");
        if (_game.iBlock == block.number)
            return _drawFailure(_id, _draws, "Initial cards not available.");
        if (_game.dBlock != 0)
            return _drawFailure(_id, _draws, "Cards already drawn.");
        if (_draws > 31)
            return _drawFailure(_id, _draws, "Invalid draws.");
        if (_draws == 0)
            return _drawFailure(_id, _draws, "Cannot draw 0 cards. Use finalize instead.");
        if (_game.handRank != HAND_UNDEFINED)
            return _drawFailure(_id, _draws, "Game already finalized.");
        
        _draw(_game, _id, _draws, _hashCheck);
    }
        function _drawFailure(uint32 _id, uint8 _draws, string _msg)
            private
        {
            emit DrawFailure(now, msg.sender, _id, _draws, _msg);
        }
      

     
     
     
     
     
     
     
    function finalize(uint32 _id, bytes32 _hashCheck)
        public
        returns (bool _didFinalize)
    {
        Game storage _game = games[_id];
        address _user = userAddresses[_game.userId];
        if (_game.iBlock == 0)
            return _finalizeFailure(_id, "Invalid game Id.");
        if (_user != msg.sender)
            return _finalizeFailure(_id, "This is not your game.");
        if (_game.iBlock == block.number)
            return _finalizeFailure(_id, "Initial hand not avaiable.");
        if (_game.dBlock == block.number)
            return _finalizeFailure(_id, "Drawn cards not available.");
        if (_game.handRank != HAND_UNDEFINED)
            return _finalizeFailure(_id, "Game already finalized.");

        _finalize(_game, _id, _hashCheck);
        return true;
    }
        function _finalizeFailure(uint32 _id, string _msg)
            private
            returns (bool)
        {
            emit FinalizeFailure(now, msg.sender, _id, _msg);
            return false;
        }


     
     
     

     
     
    function _addPayTable(
        uint16 _rf, uint16 _sf, uint16 _fk, uint16 _fh,
        uint16 _fl, uint16 _st, uint16 _tk, uint16 _tp, uint16 _jb
    )
        private
    {
        require(_rf<=1600 && _sf<=100 && _fk<=50 && _fh<=18 && _fl<=12 
                 && _st<=8 && _tk<=6 && _tp<=4 && _jb<=2);

        uint16[12] memory _pt;
        _pt[HAND_UNDEFINED] = 0;
        _pt[HAND_RF] = _rf;
        _pt[HAND_SF] = _sf;
        _pt[HAND_FK] = _fk;
        _pt[HAND_FH] = _fh;
        _pt[HAND_FL] = _fl;
        _pt[HAND_ST] = _st;
        _pt[HAND_TK] = _tk;
        _pt[HAND_TP] = _tp;
        _pt[HAND_JB] = _jb;
        _pt[HAND_HC] = 0;
        _pt[HAND_NOT_COMPUTABLE] = 0;
        payTables[settings.numPayTables] = _pt;
        settings.numPayTables++;
    }

     
     
    function _creditUser(address _user, uint _amt, uint32 _gameId)
        private
    {
        if (_amt == 0) return;
        uint64 _incr = _gameId == 0 ? 0 : uint64(_amt / 1e9);
        uint88 _totalCredits = vars.totalCredits + uint88(_amt);
        uint64 _totalWonGwei = vars.totalWonGwei + _incr;
        vars.totalCredits = _totalCredits;
        vars.totalWonGwei = _totalWonGwei;
        credits[_user] += _amt;
        emit CreditsAdded(now, _user, _gameId, _amt);
    }

     
     
    function _uncreditUser(address _user, uint _amt)
        private
    {
        if (_amt > credits[_user] || _amt == 0) _amt = credits[_user];
        if (_amt == 0) return;
        vars.totalCredits -= uint88(_amt);
        credits[_user] -= _amt;
        require(_user.call.value(_amt)());
        emit CreditsCashedout(now, _user, _amt);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function _createNewGame(uint64 _bet)
        private
        returns (uint32 _curId)
    {
         
        uint32 _curUserId = vars.curUserId;
        uint32 _userId = userIds[msg.sender];
        if (_userId == 0) {
            _curUserId++;
            userIds[msg.sender] = _curUserId;
            userAddresses[_curUserId] = msg.sender;
            _userId = _curUserId;
        }

         
        _curId =  vars.curId + 1;
        uint64 _totalWagered = vars.totalWageredGwei + _bet / 1e9;
        vars.curId = _curId;
        vars.totalWageredGwei = _totalWagered;
        vars.curUserId = _curUserId;

         
        uint16 _payTableId = settings.curPayTableId;
        Game storage _game = games[_curId];
        _game.userId = _userId;
        _game.bet = _bet;
        _game.payTableId = _payTableId;
        _game.iBlock = uint32(block.number);
        return _curId;
    }

     
     
     
     
     
     
    function _draw(Game storage _game, uint32 _id, uint8 _draws, bytes32 _hashCheck)
        private
    {
         
        assert(_game.dBlock == 0);

         
        uint32 _iHand;
        bytes32 _iBlockHash = blockhash(_game.iBlock);
        uint8 _warnCode;
        if (_iBlockHash != 0) {
             
            if (_iBlockHash != _hashCheck) {
                return _drawFailure(_id, _draws, "HashCheck Failed. Try refreshing game.");
            }
            _iHand = getHand(uint(keccak256(_iBlockHash, _id)));
        } else {
            _warnCode = WARN_IHAND_TIMEOUT;
            _draws = 31;
        }

         
        _game.iHand = _iHand;
        _game.draws = _draws;
        _game.dBlock = uint32(block.number);

        emit DrawSuccess(now, msg.sender, _id, _game.iHand, _draws, _warnCode);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function _finalize(Game storage _game, uint32 _id, bytes32 _hashCheck)
        private
    {
         
        assert(_game.handRank == HAND_UNDEFINED);

         
        address _user = userAddresses[_game.userId];
        bytes32 _blockhash;
        uint32 _dHand;
        uint32 _iHand;   
        uint8 _warnCode;
        if (_game.draws != 0) {
            _blockhash = blockhash(_game.dBlock);
            if (_blockhash != 0) {
                 
                _dHand = drawToHand(uint(keccak256(_blockhash, _id)), _game.iHand, _game.draws);
            } else {
                 
                if (_game.iHand != 0){
                    _dHand = _game.iHand;
                    _warnCode = WARN_DHAND_TIMEOUT;
                } else {
                    _dHand = 0;
                    _warnCode = WARN_BOTH_TIMEOUT;
                }
            }
        } else {
            _blockhash = blockhash(_game.iBlock);
            if (_blockhash != 0) {
                 
                if (_blockhash != _hashCheck) {
                    _finalizeFailure(_id, "HashCheck Failed. Try refreshing game.");
                    return;
                }
                 
                _iHand = getHand(uint(keccak256(_blockhash, _id)));
                _dHand = _iHand;
            } else {
                 
                _finalizeFailure(_id, "Initial hand not available. Drawing 5 new cards.");
                _game.draws = 31;
                _game.dBlock = uint32(block.number);
                emit DrawSuccess(now, _user, _id, 0, 31, WARN_IHAND_TIMEOUT);
                return;
            }
        }

         
        uint8 _handRank = _dHand == 0
            ? uint8(HAND_NOT_COMPUTABLE)
            : uint8(getHandRank(_dHand));

         
        if (_iHand > 0) _game.iHand = _iHand;
         
        _game.dHand = _dHand;
        _game.handRank = _handRank;

         
        uint _payout = payTables[_game.payTableId][_handRank] * uint(_game.bet);
        if (_payout > 0) _creditUser(_user, _payout, _id);
        emit FinalizeSuccess(now, _user, _id, _game.dHand, _game.handRank, _payout, _warnCode);
    }



     
     
     

     
     
    function getCollateral() public view returns (uint _amount) {
        return vars.totalCredits;
    }

     
     
    function getWhitelistOwner() public view returns (address _wlOwner) {
        return getAdmin();
    }

     
     
     
    function curMaxBet() public view returns (uint) {
         
        uint _maxPayout = payTables[settings.curPayTableId][HAND_RF] * 2;
        return bankrollAvailable() / _maxPayout;
    }

     
    function effectiveMaxBet() public view returns (uint _amount) {
        uint _curMax = curMaxBet();
        return _curMax > settings.maxBet ? settings.maxBet : _curMax;
    }

    function getPayTable(uint16 _payTableId)
        public
        view
        returns (uint16[12])
    {
        require(_payTableId < settings.numPayTables);
        return payTables[_payTableId];
    }

    function getCurPayTable()
        public
        view
        returns (uint16[12])
    {
        return getPayTable(settings.curPayTableId);
    }

     
    function getIHand(uint32 _id)
        public
        view
        returns (uint32)
    {
        Game memory _game = games[_id];
        if (_game.iHand != 0) return _game.iHand;
        if (_game.iBlock == 0) return;
        
        bytes32 _iBlockHash = blockhash(_game.iBlock);
        if (_iBlockHash == 0) return;
        return getHand(uint(keccak256(_iBlockHash, _id)));
    }

     
     
    function getDHand(uint32 _id)
        public
        view
        returns (uint32)
    {
        Game memory _game = games[_id];
        if (_game.dHand != 0) return _game.dHand;
        if (_game.draws == 0) return _game.iHand;
        if (_game.dBlock == 0) return;

        bytes32 _dBlockHash = blockhash(_game.dBlock);
        if (_dBlockHash == 0) return _game.iHand;
        return drawToHand(uint(keccak256(_dBlockHash, _id)), _game.iHand, _game.draws);
    }

     
    function getDHandRank(uint32 _id)
        public
        view
        returns (uint8)
    {
        uint32 _dHand = getDHand(_id);
        return _dHand == 0
            ? uint8(HAND_NOT_COMPUTABLE)
            : uint8(getHandRank(_dHand));
    }

     
    function curId() public view returns (uint32) {
        return vars.curId;
    }
    function totalWagered() public view returns (uint) {
        return uint(vars.totalWageredGwei) * 1e9;
    }
    function curUserId() public view returns (uint) {
        return uint(vars.curUserId);
    }
    function totalWon() public view returns (uint) {
        return uint(vars.totalWonGwei) * 1e9;
    }
    function totalCredits() public view returns (uint) {
        return vars.totalCredits;
    }
     

     
    function minBet() public view returns (uint) {
        return settings.minBet;
    }
    function maxBet() public view returns (uint) {
        return settings.maxBet;
    }
    function curPayTableId() public view returns (uint) {
        return settings.curPayTableId;
    }
    function numPayTables() public view returns (uint) {
        return settings.numPayTables;
    }
     
}