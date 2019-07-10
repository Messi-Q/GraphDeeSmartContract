pragma solidity ^0.4.24;

contract FDDEvents {

     
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );
    
     
    event onEndTx
    (
        uint256 compressedData,     
        uint256 compressedIDs,      
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );
    
	 
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );
    
     
    event onWithdrawAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
     
     
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
     
     
    event onReLoadAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 genAmount
    );
    
     
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
}

contract modularFomoDD is FDDEvents {}

contract FomoDD is modularFomoDD {
    using SafeMath for *;
    using NameFilter for string;
    using FDDKeysCalc for uint256;
	
     
    BankInterfaceForForwarder constant private Bank = BankInterfaceForForwarder(0xfa1678C00299fB685794865eA5e20dB155a8C913);
	PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xA5d855212A9475558ACf92338F6a1df44dFCE908);

    address private admin = msg.sender;
    string constant public name = "FomoDD";
    string constant public symbol = "Chives";

     
    uint256 private rndGap_ = 0;
    uint256 private rndExtra_ = 0 minutes;
    uint256 constant private rndInit_ = 12 hours;                 
    uint256 constant private rndInc_ = 30 seconds;               
    uint256 constant private rndMax_ = 24 hours;                 

	uint256 public airDropPot_;              
    uint256 public airDropTracker_ = 0;      

    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => FDDdatasets.Player) public plyr_;    
    mapping (uint256 => FDDdatasets.PlayerRounds) public plyrRnds_;  
    mapping (uint256 => mapping (uint256 => FDDdatasets.PlayerRounds)) public plyrRnds;  
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;

    uint256 public rID_;     
    FDDdatasets.Round public round_;    
    mapping (uint256 => FDDdatasets.Round) public round;  

    uint256 public fees_ = 60;           
    uint256 public potSplit_ = 45;      

    constructor() public { }

    modifier isActivated() {
        require(activated_ == true, "its not ready yet"); 
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "non smart contract address only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "too little money");
        require(_eth <= 100000000000000000000000, "too much money");
        _;    
    }

    function() isActivated() isHuman() isWithinLimits(msg.value) public payable {
        FDDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);             
        uint256 _pID = pIDxAddr_[msg.sender];
        buyCore(_pID, plyr_[_pID].laff, _eventData_);
    }
    
     
    function buyXid(uint256 _affCode)  isActivated()  isHuman() isWithinLimits(msg.value)  public payable {
         
        FDDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        uint256 _pID = pIDxAddr_[msg.sender];

        if (_affCode == 0 || _affCode == _pID) {
             
            _affCode = plyr_[_pID].laff;

        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

        buyCore(_pID, _affCode, _eventData_);
    }
    
    function buyXaddr(address _affCode) isActivated() isHuman() isWithinLimits(msg.value) public payable {
         
        FDDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        uint256 _pID = pIDxAddr_[msg.sender];

        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender) {
            _affID = plyr_[_pID].laff;

        } else {
             
            _affID = pIDxAddr_[_affCode];

            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

        buyCore(_pID, _affID, _eventData_);
    }
    
    function buyXname(bytes32 _affCode) isActivated() isHuman() isWithinLimits(msg.value) public payable {
         
        FDDdatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        uint256 _pID = pIDxAddr_[msg.sender];

        uint256 _affID;
         
        if (_affCode == '' || _affCode == plyr_[_pID].name) {
            _affID = plyr_[_pID].laff;
        } else {
            _affID = pIDxName_[_affCode];

            if (_affID != plyr_[_pID].laff) {
                plyr_[_pID].laff = _affID;
            }
        }

        buyCore(_pID, _affID, _eventData_);
    }

    function reLoadXid(uint256 _affCode, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
         
        FDDdatasets.EventReturns memory _eventData_;

        uint256 _pID = pIDxAddr_[msg.sender];

        if (_affCode == 0 || _affCode == _pID) {
             
            _affCode = plyr_[_pID].laff;

        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

        reLoadCore(_pID, _affCode, _eth, _eventData_);
    }
    
    function reLoadXaddr(address _affCode, uint256 _eth) isActivated() isHuman() isWithinLimits(_eth) public {
         
        FDDdatasets.EventReturns memory _eventData_;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxAddr_[_affCode];
            
            if (_affID != plyr_[_pID].laff)  {
                 
                plyr_[_pID].laff = _affID;
            }
        }
                
         
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }
    
    function reLoadXname(bytes32 _affCode, uint256 _eth)        isActivated()        isHuman()        isWithinLimits(_eth)        public    {
         
        FDDdatasets.EventReturns memory _eventData_;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == '' || _affCode == plyr_[_pID].name)        {
             
            _affID = plyr_[_pID].laff;
        
         
        } else {
             
            _affID = pIDxName_[_affCode];
            
             
            if (_affID != plyr_[_pID].laff)            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
                
         
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }

     
    function withdraw()        isActivated()        isHuman()        public    {
        uint256 _rID = rID_;

         
        uint256 _now = now;
        
         
        uint256 _pID = pIDxAddr_[msg.sender];
        
         
        uint256 _eth;
        
         
        if (_now > round[_rID].end && round[_rID].ended == false && round[_rID].plyr != 0)    {
             
            FDDdatasets.EventReturns memory _eventData_;
            round[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            
			 
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)    plyr_[_pID].addr.transfer(_eth);    
            
             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
            
             
            emit FDDEvents.onWithdrawAndDistribute
            (
                msg.sender, 
                plyr_[_pID].name, 
                _eth, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.genAmount
            );
         
        } else {
             
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            
             
            emit FDDEvents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }
    
     
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)        isHuman()        public        payable    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];
        
         
        emit FDDEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
    function registerNameXaddr(string _nameString, address _affCode, bool _all)        isHuman()        public        payable    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
         
        emit FDDEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)        isHuman()        public        payable    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
         
        emit FDDEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
 
 
 
 
     
    function getBuyPrice()        public         view         returns(uint256)    {
        uint256 _rID = rID_;          
         
        uint256 _now = now;
        
         
        if (_now > round[_rID].strt + rndGap_ && (_now <= round[_rID].end || (_now > round[_rID].end && round[_rID].plyr == 0)))
            return ( (round[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else  
            return ( 75000000000000 );  
    }
    
     
    function getTimeLeft()        public        view        returns(uint256)    {
        uint256 _rID = rID_;
         
        uint256 _now = now;
        
        if (_now < round[_rID].end)
            if (_now > round[_rID].strt + rndGap_)
                return( (round[_rID].end).sub(_now) );
            else
                return( (round[_rID].strt + rndGap_).sub(_now));
        else
            return(0);
    }
    
     
    function getPlayerVaults(uint256 _pID)        public        view        returns(uint256 ,uint256, uint256)    {
        uint256 _rID = rID_;

         
        if (now > round[_rID].end && round[_rID].ended == false && round[_rID].plyr != 0)        {
             
            if (round[_rID].plyr == _pID)            {
                return   (
                    (plyr_[_pID].win).add( ((round[_rID].pot).mul(48)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
             
            } else {
                return    (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }
            plyrRnds_[_pID] = plyrRnds[_pID][_rID];
         
        } else {
            return   (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }
    
     
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)        private        view        returns(uint256)    {
        return(  ((((round[_rID].mask).add(((((round[_rID].pot).mul(potSplit_)) / 100).mul(1000000000000000000)) / (round[_rID].keys))).mul(plyrRnds[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    
     
    function getCurrentRoundInfo()        public        view        returns(uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256)    {
        uint256 _rID = rID_;
        return   (
            round[_rID].keys,               
            round[_rID].end,                
            round[_rID].strt,               
            round[_rID].pot,                
            round[_rID].plyr,               
            plyr_[round[_rID].plyr].addr,   
            plyr_[round[_rID].plyr].name,   
            airDropTracker_ + (airDropPot_ * 1000)               
        );
    }

     
    function getPlayerInfoByAddress(address _addr)        public         view         returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)    {
        uint256 _rID = rID_;

        if (_addr == address(0))        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return     (
            _pID,                                
            plyr_[_pID].name,                    
            plyrRnds[_pID][_rID].keys,          
            plyr_[_pID].win,                     
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        
            plyr_[_pID].aff,                     
            plyrRnds[_pID][_rID].eth            
        );
    }

     
    function buyCore(uint256 _pID, uint256 _affID, FDDdatasets.EventReturns memory _eventData_)   private  {
        uint256 _rID = rID_;

         
        uint256 _now = now;
        
         
        if (_now > round[_rID].strt + rndGap_ && (_now <= round[_rID].end || (_now > round[_rID].end && round[_rID].plyr == 0)))     {
             
            core(_rID, _pID, msg.value, _affID, _eventData_);
        
         
        } else {
             
            if (_now > round[_rID].end && round[_rID].ended == false)   {
                 
			    round[_rID].ended = true;
                _eventData_ = endRound(_eventData_);
                
                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
                 
                emit FDDEvents.onBuyAndDistribute
                (
                    msg.sender, 
                    plyr_[_pID].name, 
                    msg.value, 
                    _eventData_.compressedData, 
                    _eventData_.compressedIDs, 
                    _eventData_.winnerAddr, 
                    _eventData_.winnerName, 
                    _eventData_.amountWon, 
                    _eventData_.newPot, 
                    _eventData_.genAmount
                );
            }
            
             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    
     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, FDDdatasets.EventReturns memory _eventData_)   private  {
        uint256 _rID = rID_;

         
        uint256 _now = now;
        
         
        if (_now > round[_rID].strt + rndGap_ && (_now <= round[_rID].end || (_now > round[_rID].end && round[_rID].plyr == 0)))    {
             
   
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            
             
            core(_rID, _pID, _eth, _affID, _eventData_);
        
         
        } else if (_now > round[_rID].end && round[_rID].ended == false) {
             
            round[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
                
             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
             
            emit FDDEvents.onReLoadAndDistribute
            (
                msg.sender, 
                plyr_[_pID].name, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.genAmount
            );
        }
    }
    
     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, FDDdatasets.EventReturns memory _eventData_)  private  {
        if (plyrRnds[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

        if (round[_rID].eth < 100000000000000000000 && plyrRnds[_pID][_rID].eth.add(_eth) > 10000000000000000000)  {
            uint256 _availableLimit = (10000000000000000000).sub(plyrRnds[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
       if (_eth > 1000000000)  {
          uint256 _keys = (round[_rID].eth).keysRec(_eth);
            if (_keys >= 1000000000000000000)   {
                updateTimer(_keys, _rID);
                if (round[_rID].plyr != _pID)
                    round[_rID].plyr = _pID;  

                _eventData_.compressedData = _eventData_.compressedData + 100;
            }

            if (_eth >= 100000000000000000)  {
                airDropTracker_++;
                if (airdrop() == true)  {
                    uint256 _prize;
                    if (_eth >= 10000000000000000000) {
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);
                        _eventData_.compressedData += 200000000000000000000000000000000;
                    } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);
                        _eventData_.compressedData += 100000000000000000000000000000000;
                    }
                     
                    _eventData_.compressedData += 10000000000000000000000000000000;
                    _eventData_.compressedData += _prize * 1000000000000000000000000000000000;
                    airDropTracker_ = 0;
                }
            }

            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);

            plyrRnds[_pID][_rID].keys = _keys.add(plyrRnds[_pID][_rID].keys);
            plyrRnds[_pID][_rID].eth = _eth.add(plyrRnds[_pID][_rID].eth);
            
             
            round[_rID].keys = _keys.add(round[_rID].keys);
            round[_rID].eth = _eth.add(round[_rID].eth);
             
            _eventData_ = distributeExternal(_pID, _eth, _affID, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _keys, _eventData_);
             
		    endTx(_pID, _eth, _keys, _eventData_);
        }
        plyrRnds_[_pID] = plyrRnds[_pID][_rID];
        round_ = round[_rID];
    }
 

     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)        private        view        returns(uint256)    {
        return((((round[_rIDlast].mask).mul(plyrRnds[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds[_pID][_rIDlast].mask));
    }
    
     
    function calcKeysReceived(uint256 _eth)        public        view        returns(uint256)    {
        uint256 _rID = rID_;
         
        uint256 _now = now;
        
         
        if (_now > round[_rID].strt + rndGap_ && (_now <= round[_rID].end || (_now > round[_rID].end && round[_rID].plyr == 0)))
            return ( (round[_rID].eth).keysRec(_eth) );
        else  
            return ( (_eth).keys() );
    }
    
     
    function iWantXKeys(uint256 _keys)        public        view        returns(uint256)    {
        uint256 _rID = rID_;
         
        uint256 _now = now;
        
         
        if (_now > round[_rID].strt + rndGap_ && (_now <= round[_rID].end || (_now > round[_rID].end && round[_rID].plyr == 0)))
            return ( (round[_rID].keys.add(_keys)).ethRec(_keys) );
        else  
            return ( (_keys).eth() );
    }
 

    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)        external    {
        require (msg.sender == address(PlayerBook), "only PlayerBook can call this function");
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
        if (plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;
        if (plyr_[_pID].laff != _laff)
            plyr_[_pID].laff = _laff;
        if (plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }
    
     
    function receivePlayerNameList(uint256 _pID, bytes32 _name)        external {
        require (msg.sender == address(PlayerBook), "only PlayerBook can call this function");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }   
        
     
    function determinePID(FDDdatasets.EventReturns memory _eventData_)        private        returns (FDDdatasets.EventReturns)    {
        uint256 _pID = pIDxAddr_[msg.sender];
         
        if (_pID == 0)        {
             
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            
             
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            
            if (_name != "")            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }
            
            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;
            
             
            _eventData_.compressedData = _eventData_.compressedData + 1;
        } 
        return (_eventData_);
    }

     
    function managePlayer(uint256 _pID, FDDdatasets.EventReturns memory _eventData_)        private        returns (FDDdatasets.EventReturns)    {
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

        plyr_[_pID].lrnd = rID_;            
         
        _eventData_.compressedData = _eventData_.compressedData + 10;
        
        return(_eventData_);
    }
    
     
    function endRound(FDDdatasets.EventReturns memory _eventData_)        private        returns (FDDdatasets.EventReturns)    {        
        uint256 _rID = rID_;
         
        uint256 _winPID = round[_rID].plyr;
     
        uint256 _pot = round[_rID].pot;
 
        uint256 _win = (_pot.mul(45)) / 100;
        uint256 _com = (_pot / 10);
        uint256 _gen = (_pot.mul(potSplit_)) / 100;
        
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)        {
            _gen = _gen.sub(_dust);
            _com = _com.add(_dust);
        }
        
         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);
   
         
        round[_rID].mask = _ppt.add(round[_rID].mask);
            
         
        _eventData_.compressedData = _eventData_.compressedData + (round[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.newPot = _com;
        
         
        rID_++;
        _rID++;
        round[_rID].strt = now + rndExtra_;
        round[_rID].end = now + rndInit_ + rndExtra_;
        round[_rID].pot = _com;
        round_ = round[_rID];

        return(_eventData_);
    }
    
     
    function updateGenVault(uint256 _pID, uint256 _rIDlast)        private     {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)        {
             
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
             
            plyrRnds[_pID][_rIDlast].mask = _earnings.add(plyrRnds[_pID][_rIDlast].mask);
            plyrRnds_[_pID] = plyrRnds[_pID][_rIDlast];
        }
    }
    
     
    function updateTimer(uint256 _keys, uint256 _rID)        private    {
         
        uint256 _now = now;
        
         
        uint256 _newTime;
        if (_now > round[_rID].end && round[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round[_rID].end);
        
         
        if (_newTime < (rndMax_).add(_now))
            round[_rID].end = _newTime;
        else
            round[_rID].end = rndMax_.add(_now);

        round_ = round[_rID];
    }
    
     
    function airdrop()        private         view         returns(bool)    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return(true);
        else
            return(false);
    }

     
    function distributeExternal(uint256 _pID, uint256 _eth, uint256 _affID, FDDdatasets.EventReturns memory _eventData_) private returns(FDDdatasets.EventReturns) {
        uint256 _com = _eth * 5 / 100;
        uint256 _aff = _eth * 10 / 100;
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit FDDEvents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _pID, _aff, now);
        } else {
            _com += _aff;
        }

        if (!address(Bank).call.value(_com)(bytes4(keccak256("deposit()"))))  {  }
        return(_eventData_);
    }
    
     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _keys, FDDdatasets.EventReturns memory _eventData_) private  returns(FDDdatasets.EventReturns)    {
         
        uint256 _gen = (_eth.mul(fees_)) / 100;
        
         
        uint256 _air = (_eth / 20);
        airDropPot_ = airDropPot_.add(_air);
                
         
        uint256 _pot = (_eth.mul(20) / 100);
        
         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
         
        round[_rID].pot = _pot.add(_dust).add(round[_rID].pot);
        
         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        round_ = round[_rID];

        return(_eventData_);
    }

     
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys) private   returns(uint256)    {
         
        
         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round[_rID].keys);
        round[_rID].mask = _ppt.add(round[_rID].mask);
            
         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds[_pID][_rID].mask = (((round[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds[_pID][_rID].mask);
        plyrRnds_[_pID] = plyrRnds[_pID][_rID];
        round_ = round[_rID];
         
        return(_gen.sub((_ppt.mul(round[_rID].keys)) / (1000000000000000000)));
    }
    
     
    function withdrawEarnings(uint256 _pID)        private        returns(uint256)    {
         
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
     
    function endTx(uint256 _pID, uint256 _eth, uint256 _keys, FDDdatasets.EventReturns memory _eventData_)    private    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
        
        emit FDDEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

     
    bool public activated_ = false;

    function activate()   public    {
         
         
        require(msg.sender == admin);
        
         
        require(activated_ == false, "FomoDD already activated");
        
         
        activated_ = true;
        
        rID_ = 1;
        round[1].strt = now + rndExtra_;
        round[1].end = now + rndInit_ + rndExtra_;
        round_ = round[1];
    }
}

 
library FDDdatasets {

    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 genAmount;           
        uint256 potAmount;           
    }
    struct Player {
        address addr;    
        bytes32 name;    
        uint256 win;     
        uint256 gen;     
        uint256 aff;     
        uint256 lrnd;    
        uint256 laff;    
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 mask;    
    }
    struct Round {
        uint256 plyr;    
        uint256 end;     
        bool ended;      
        uint256 strt;
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
    }
}

 
library FDDKeysCalc {
    using SafeMath for *;
     
    function keysRec(uint256 _curEth, uint256 _newEth)        internal        pure        returns (uint256)    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
     
    function ethRec(uint256 _curKeys, uint256 _sellKeys)        internal        pure        returns (uint256)    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

     
    function keys(uint256 _eth)         internal        pure        returns(uint256)    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
     
    function eth(uint256 _keys)         internal        pure        returns(uint256)      {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

interface BankInterfaceForForwarder {
    function deposit() external payable returns(bool);
}

interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}

library NameFilter {
     
    function nameFilter(string _input)        internal        pure        returns(bytes32)    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
         
        bool _hasNonNumber;
        
         
        for (uint256 i = 0; i < _length; i++)        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require    (
                     
                    _temp[i] == 0x20 ||                   
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)   require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

 
library SafeMath {
    

    function mul(uint256 a, uint256 b)         internal         pure         returns (uint256 c)     {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)        internal        pure        returns (uint256)     {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)        internal        pure        returns (uint256 c)     {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

     
    function sqrt(uint256 x)        internal        pure        returns (uint256 y)     {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)         {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

     
    function sq(uint256 x)        internal        pure        returns (uint256)    {
        return (mul(x,x));
    }
}