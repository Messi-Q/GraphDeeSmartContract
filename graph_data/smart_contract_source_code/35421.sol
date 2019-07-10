pragma solidity ^0.4.16;
 
 

 
contract owned  {
  address owner;
  function owned() {
    owner = msg.sender;
  }
  function changeOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
  modifier onlyOwner() {
    if (msg.sender==owner) 
    _;
  }
}

 
contract mortal is owned() {
  function kill() onlyOwner {
    if (msg.sender == owner) selfdestruct(owner);
  }
}

 
contract DSMath {

	 

	 
	 

	 
	 
	 
    
	 
     
     

    function hmore(uint128 x, uint128 y) constant internal returns (bool) {
        return x>y;
    }

    function hless(uint128 x, uint128 y) constant internal returns (bool) {
        return x<y;
    }

    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        require(y == 0 ||(z = x * y)/ y == x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }

    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }

     
     
     

     
    uint64 constant WAD_Dec=18;
    uint128 constant WAD = 10 ** 18;

    function wmore(uint128 x, uint128 y) constant internal returns (bool) {
        return hmore(x, y);
    }

    function wless(uint128 x, uint128 y) constant internal returns (bool) {
        return hless(x, y);
    }

    function wadd(uint128 x, uint128 y) constant  returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant   returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal  returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal  returns (uint128) {
        return hmin(x, y);
    }

    function wmax(uint128 x, uint128 y) constant internal  returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }
	
}
 
 
contract I_minter { 
    event EventCreateStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventCreateRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventBankrupt();

    function Leverage() constant returns (uint128)  {}
    function RiskPrice(uint128 _currentPrice,uint128 _StaticTotal,uint128 _RiskTotal, uint128 _ETHTotal) constant returns (uint128 price)  {}
    function RiskPrice(uint128 _currentPrice) constant returns (uint128 price)  {}     
    function PriceReturn(uint _TransID,uint128 _Price) {}
    function NewStatic() external payable returns (uint _TransID)  {}
    function NewStaticAdr(address _Risk) external payable returns (uint _TransID)  {}
    function NewRisk() external payable returns (uint _TransID)  {}
    function NewRiskAdr(address _Risk) external payable returns (uint _TransID)  {}
    function RetRisk(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function RetStatic(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function Strike() constant returns (uint128)  {}
}

 
contract I_Pricer {
    uint128 public lastPrice;
    I_minter public mint;
    string public sURL;
    mapping (bytes32 => uint) RevTransaction;

    function setMinter(address _newAddress) {}
    function __callback(bytes32 myid, string result) {}
    function queryCost() constant returns (uint128 _value) {}
    function QuickPrice() payable {}
    function requestPrice(uint _actionID) payable returns (uint _TrasID) {}
    function collectFee() returns(bool) {}
    function () {
         
        revert();
    }
}

 
contract I_coin is mortal {

    event EventClear();

	I_minter public mint;
    string public name;                    
    uint8 public decimals=18;                 
    string public symbol;                  
    string public version = '';        
	
    function mintCoin(address target, uint256 mintedAmount) returns (bool success) {}
    function meltCoin(address target, uint256 meltedAmount) returns (bool success) {}
    function approveAndCall(address _spender, uint256 _value, bytes _extraData){}

    function setMinter(address _minter) {}   
	function increaseApproval (address _spender, uint256 _addedValue) returns (bool success) {}    
	function decreaseApproval (address _spender, uint256 _subtractedValue) 	returns (bool success) {} 

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}    


     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}


     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

	 
    uint256 public totalSupply;
}

 
contract DSBaseActor {
    

    bool _ds_mutex;
    modifier mutex() {
        assert(!_ds_mutex);
        _ds_mutex = true;
        _;
        _ds_mutex = false;
    }
	
    function tryExec(address target, bytes calldata, uint256 value) mutex() internal  returns (bool call_ret){
        return target.call.value(value)(calldata);
    }
	
    function exec( address target, bytes calldata, uint256 value) internal {
        assert(tryExec(target, calldata, value));
    }
}

 
contract canFreeze is owned { 
	 
	 
    bool public frozen=false;
    modifier LockIfFrozen() {
        if (!frozen){
            _;
        }
    }
    function Freeze() onlyOwner {
         
		 
        frozen=true;
    }
}

 
contract oneWrite {  
	 
	 
  bool written = false;
  function oneWrite() {
	 
    written = false;
  }
  modifier LockIfUnwritten() {
    if (written){
        _;
    }
  }
  modifier writeOnce() {
    if (!written){
        written=true;
        _;
    }
  }
}

 
contract pricerControl is canFreeze {
	 
	 
	 
	 
	 
    I_Pricer public pricer;
    address public future;
    uint256 public releaseTime;
    uint public PRICER_DELAY = 2;  
    event EventAddressChange(address indexed _from, address indexed _to, uint _timeChange);

    function setPricer(address newAddress) onlyOwner {
		 
        releaseTime = now + PRICER_DELAY;
        future = newAddress;
        EventAddressChange(pricer, future, releaseTime);
    }  

    modifier updates() {
        if (now > releaseTime  && pricer != future){
            update();
             
        }
        _;
    }

    modifier onlyPricer() {
      if (msg.sender==address(pricer))
      _;
    }

    function update() internal {
        pricer =  I_Pricer(future);
		frozen = false;
    }
}

 	
contract minter is I_minter, DSBaseActor, oneWrite, pricerControl, DSMath{  
	 
	 
	 
	 
	 
	 
	 
    enum Action {NewStatic, RetStatic, NewRisk, RetRisk}  
    struct Trans {  
        uint128 amount;  
        address holder;  
        Action action;   
		uint pricerID;   
    }
    uint128 public lastPrice;  
    uint public TransID=0;  
    string public Currency;  
    I_coin public Static;   
    I_coin public Risk;   
    uint128 public Multiplier; 
    uint128 public levToll=5*10**(18-1); 
    uint128 public mintFee = 2*10**(18-3);  
    mapping (uint => Trans[]) public pending;  

    event EventCreateStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventCreateRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventBankrupt();	 
	
	function minter(string _currency, uint128 _Multiplier) {  
         
        Currency=_currency;
        Multiplier = _Multiplier;
         
    }	

	function () {
         
        revert();
    }

	function Bailout() 	external payable 	{
         
    }
		
    function NewStatic() external payable returns (uint _TransID) {
         
		_TransID=NewCoinInternal(msg.sender,cast(msg.value),Action.NewStatic);
		 
    }
	
    function NewStaticAdr(address _user) external payable returns (uint _TransID)  {  
         
		_TransID=NewCoinInternal(_user,cast(msg.value),Action.NewStatic);
		 
    }
	
    function NewRisk() external payable returns (uint _TransID)  {
         
		_TransID=NewCoinInternal(msg.sender,cast(msg.value),Action.NewRisk);
         
    }

    function NewRiskAdr(address _user) 	external payable returns (uint _TransID)  {
         
		_TransID=NewCoinInternal(_user,cast(msg.value),Action.NewRisk);
         
    }

    function RetRisk(uint128 _Quantity) external payable LockIfUnwritten  returns (uint _TransID)  {
         
        if(frozen){
             
            TransID++;
			ActionRetRisk(Trans(_Quantity,msg.sender,Action.RetRisk,0),TransID,lastPrice);
			_TransID=TransID;
        } else {
             
			_TransID=RetCoinInternal(_Quantity,cast(msg.value),msg.sender,Action.RetRisk);
        }
		 
    }

    function RetStatic(uint128 _Quantity) external payable LockIfUnwritten returns (uint _TransID)  {
         
        if(frozen){
             
			TransID++;
            ActionRetStatic(Trans(_Quantity,msg.sender,Action.RetStatic,0),TransID,lastPrice);
			_TransID=TransID;
        } else {
             
			_TransID=RetCoinInternal(_Quantity,cast(msg.value),msg.sender,Action.RetStatic);
        }
		 
    }
	
	 
	 
    function StaticEthAvailable() 	constant returns (uint128)  {
		 
		return StaticEthAvailable(cast(Risk.totalSupply()), cast(this.balance));
    }

	function StaticEthAvailable(uint128 _RiskTotal, uint128 _TotalETH) 	constant 	returns (uint128)  {
		 
		 
		uint128 temp = wmul(wadd(Multiplier,levToll),_RiskTotal);
		if(wless(_TotalETH,temp)){
			return wsub(temp ,_TotalETH);
		} else {
			return 0;
		}
    }

	function RiskPrice(uint128 _currentPrice,uint128 _StaticTotal,uint128 _RiskTotal, uint128 _ETHTotal) constant 	returns (uint128 price)  {
	     
        if(_ETHTotal == 0 || _RiskTotal==0){
			 
            return wmul( _currentPrice , Multiplier); 
        } else {
            if(hmore( wmul(_ETHTotal , _currentPrice),_StaticTotal)){  
				 
                return wdiv(wsub(wmul(_ETHTotal , _currentPrice) , _StaticTotal) , _RiskTotal);  
            } else  {
				 
                return 0;
            }
        }       
    }

    function RiskPrice() constant returns (uint128 price)  {
	     
        return RiskPrice(lastPrice);
    }     	
	
    function RiskPrice(uint128 _currentPrice) 	constant 	returns (uint128 price)  {
	     
        return RiskPrice(_currentPrice,cast(Static.totalSupply()),cast(Risk.totalSupply()),cast(this.balance));
    }     

	function Leverage() public constant returns (uint128)  {
		 
        if(Risk.totalSupply()>0){
            return wdiv(cast(this.balance) , cast(Risk.totalSupply()));  
        }else{
            return 0;
        }
    }

    function Strike() public constant returns (uint128)  {
		  
        if(this.balance>0){
            return wdiv(cast(Static.totalSupply()) , cast(this.balance));  
        }else{
            return 0;            
        }
    }

	 
	 
    function setFee(uint128 _newFee) onlyOwner {
         
        mintFee=_newFee;
    }

    function setCoins(address newRisk,address newStatic) updates onlyOwner 	writeOnce {         
        Risk=I_coin(newRisk);
        Static=I_coin(newStatic);
		PRICER_DELAY = 2 days;
    }
	
	 
	 
    function PriceReturn(uint _TransID,uint128 _Price) 	onlyPricer {
	     
	    Trans memory details=pending[_TransID][0]; 
        if(0==_Price||frozen){  
            _Price=lastPrice;
        } else {
			if(Static.totalSupply()>0 && Risk.totalSupply()>0) { 
				lastPrice=_Price;  
			}
        }
		 
        if(Action.NewStatic==details.action){
            ActionNewStatic(details,_TransID, _Price);
        }
		 
        if(Action.RetStatic==details.action){
            ActionRetStatic(details,_TransID, _Price);
        }
		 
        if(Action.NewRisk==details.action){
            ActionNewRisk(details,_TransID, _Price);
        }
		 
        if(Action.RetRisk==details.action){
            ActionRetRisk(details,_TransID, _Price);
        }
		 
		delete pending[_TransID];
    }
	
	 
     
    function ActionNewStatic(Trans _details, uint _TransID, uint128 _Price) internal {
		 
		 
            
             
			
			uint128 CurRiskPrice=RiskPrice(_Price);
			uint128 AmountReturn;
			uint128 AmountMint;
			
			 
			uint128 StaticAvail = StaticEthAvailable(cast(Risk.totalSupply()), wsub(cast(this.balance),_details.amount)); 
						
			 
			if (wless(_details.amount,StaticAvail)) {
				 
				AmountMint = _details.amount;
				AmountReturn = 0;
			} else {
				 
				 
				 
				AmountMint = StaticAvail;
				AmountReturn = wsub(_details.amount , StaticAvail) ;
			}	
			
			if(0 == CurRiskPrice){
				 
				AmountReturn = _details.amount;
				 
			}
			
			 
            if(CurRiskPrice > 0  && StaticAvail>0 ){
                 
				 
                Static.mintCoin(_details.holder, uint256(wmul(AmountMint , _Price)));  
                EventCreateStatic(_details.holder, wmul(AmountMint , _Price), _TransID, _Price);  
            } 

			if (AmountReturn>0) {
                 
				bytes memory calldata;  
                exec(_details.holder,calldata, AmountReturn);   
			}	
    }

    function ActionNewRisk(Trans _details, uint _TransID,uint128 _Price) internal {
		 
   
		uint128 CurRiskPrice;
		if(wless(cast(this.balance),_details.amount)){
			CurRiskPrice=RiskPrice(_Price,cast(Static.totalSupply()),cast(Risk.totalSupply()),0);
		} else {
			CurRiskPrice=RiskPrice(_Price,cast(Static.totalSupply()),cast(Risk.totalSupply()),wsub(cast(this.balance),_details.amount));
		}
        if(CurRiskPrice>0){
            uint128 quantity=wdiv(wmul(_details.amount , _Price),CurRiskPrice);   
            Risk.mintCoin(_details.holder, uint256(quantity) );   
            EventCreateRisk(_details.holder, quantity, _TransID, _Price);  
        } else {
             
            bytes memory calldata;  
            exec(_details.holder,calldata, _details.amount);
        }
    }

    function ActionRetStatic(Trans _details, uint _TransID,uint128 _Price) 	internal {
		 
		 
		 
		uint128 _ETHReturned;
		if(0==Risk.totalSupply()){_Price=lastPrice;}  
        _ETHReturned = wdiv(_details.amount , _Price);  
        if (Static.meltCoin(_details.holder,_details.amount)){
             
            EventRedeemStatic(_details.holder,_details.amount ,_TransID, _Price);
            if (wless(cast(this.balance),_ETHReturned)) {
                 _ETHReturned=cast(this.balance); 
            }
			bytes memory calldata;  
            if (tryExec(_details.holder, calldata, _ETHReturned)) { 
				 
			} else {
				 
				Static.mintCoin(_details.holder,_details.amount);  
				EventCreateStatic(_details.holder,_details.amount ,_TransID, _Price);   
			}
			if ( 0==this.balance) {
				Bankrupt();
			}
        }        
    }

    function ActionRetRisk(Trans _details, uint _TransID,uint128 _Price) internal {
		         
		 
		 
        uint128 _ETHReturned;
		uint128 CurRiskPrice;
		 
		CurRiskPrice=RiskPrice(_Price);
        if(CurRiskPrice>0){
            _ETHReturned = wdiv( wmul(_details.amount , CurRiskPrice) , _Price);  
            if (Risk.meltCoin(_details.holder,_details.amount )){
                 
                EventRedeemRisk(_details.holder,_details.amount ,_TransID, _Price);
                if ( wless(cast(this.balance),_ETHReturned)) {  
                     _ETHReturned=cast(this.balance);
                }
				bytes memory calldata;  
                if (tryExec(_details.holder, calldata, _ETHReturned)) { 
					 
                } else {
                     
                    Risk.mintCoin(_details.holder,_details.amount);
                    EventCreateRisk(_details.holder,_details.amount ,_TransID, _Price);
                }
            } 
        }  else {
             
        }
    }

	function IsWallet(address _address) internal returns(bool){
		 		
		uint codeLength;
		assembly {
             
            codeLength := extcodesize(_address)
        }
		return(0==codeLength);		
    } 

	function RetCoinInternal(uint128 _Quantity, uint128 _AmountETH, address _user, Action _action) internal updates	returns (uint _TransID)  {
         
		require(IsWallet(_user));
		uint128 refund;
        uint128 Fee=pricer.queryCost();   
		if(wless(_AmountETH,Fee)){
			revert();   
			} else {
			refund=wsub(_AmountETH,Fee); 
		}
		if(0==_Quantity){revert();} 
		TransID++;
        
        uint PricerID = pricer.requestPrice.value(uint256(Fee))(TransID);   
		pending[TransID].push(Trans(_Quantity,_user,_action,PricerID));   
        _TransID=TransID;   
        _user.transfer(uint256(refund));  
    }
		
	function NewCoinInternal(address _user, uint128 _amount, Action _action) internal updates LockIfUnwritten LockIfFrozen  returns (uint _TransID)  {
		 
		require(IsWallet(_user));
        uint128 Fee=wmax(wmul(_amount,mintFee),pricer.queryCost());  
        if(wless(_amount,Fee)) revert();  
		TransID++;
        uint PricerID = pricer.requestPrice.value(uint256(Fee))(TransID);  
		pending[TransID].push(Trans(wsub(_amount,Fee),_user,_action,PricerID));  
        _TransID=TransID; 
	} 

    function Bankrupt() internal {
			EventBankrupt();
			 
			Static.kill();   
			Risk.kill();   
			 
			frozen=false;
			written=false;   
    }
}