pragma solidity ^0.4.11;

	 
	 
	 


contract SafeMath {
	
    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }
	
	function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }
	
	function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x <= y ? x : y;
    }
}


contract Owned {
    
	address public owner;
    address public newOwner;
	
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert (msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


 
 
contract ERC20 {
	
	function totalSupply() constant returns (uint totalSupply);
	function balanceOf(address who) constant returns (uint);
	function allowance(address owner, address spender) constant returns (uint);
	
	function transfer(address to, uint value) returns (bool ok);
	function transferFrom(address from, address to, uint value) returns (bool ok);
	function approve(address spender, uint value) returns (bool ok);
  
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


contract StandardToken is ERC20, SafeMath {
	
	uint256                                            _totalSupply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    modifier onlyPayloadSize(uint numwords) {
		assert(msg.data.length == numwords * 32 + 4);
        _;
   }
   
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _who) constant returns (uint256) {
        return _balances[_who];
    }
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return _approvals[_owner][_spender];
    }
    
    function transfer(address _to, uint _value) onlyPayloadSize(2) returns (bool success) {
        assert(_balances[msg.sender] >= _value);
        
        _balances[msg.sender] = sub(_balances[msg.sender], _value);
        _balances[_to] = add(_balances[_to], _value);
        
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3) returns (bool success) {
        assert(_balances[_from] >= _value);
        assert(_approvals[_from][msg.sender] >= _value);
        
        _approvals[_from][msg.sender] = sub(_approvals[_from][msg.sender], _value);
        _balances[_from] = sub(_balances[_from], _value);
        _balances[_to] = add(_balances[_to], _value);
        
        Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success) {
        _approvals[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        
        return true;
    }

}

contract HUNT is StandardToken, Owned {

     
	string public constant name = "HUNT";
    string public constant symbol = "HT";
    uint8 public constant decimals = 18;
	
     
	uint256 public capTokens;
    uint256 public startDate;
    uint256 public endDate;
    uint public curs;
	
	address addrcnt;
	uint256 public totalTokens;
	uint256 public totalEthers;
	mapping (address => uint256) _userBonus;
	
    event BoughtTokens(address indexed buyer, uint256 ethers,uint256 newEtherBalance, uint256 tokens, uint _buyPrice);
	event Collect(address indexed addrcnt,uint256 amount);
	
    function HUNT(uint256 _start, uint256 _end, uint256 _capTokens, uint _curs, address _addrcnt) {
        startDate	= _start;
		endDate		= _end;
        capTokens   = _capTokens;
        addrcnt  	= _addrcnt;
		curs		= _curs;
    }

	function time() internal constant returns (uint) {
        return block.timestamp;
    }
	
     
     
     
     
     
     
    
    
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(time());
    }

	function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 2 days)) {
            return div(curs,100);
        } else if (at < (startDate + 5 days)) {
            return div(curs,120);
        } else if (at < (startDate + 10 days)) {
            return div(curs,130);
        } else if (at < (startDate + 15 days)) {
            return div(curs,140);
        } else if (at <= endDate) {
            return div(curs,150);
        } else {
            return 0;
        }
    }

     
    function () payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address participant) payable {
        
		 
        require(time() >= startDate);
        
		 
        require(time() <= endDate);
        
		 
        require(msg.value > 0);

         
        totalEthers = add(totalEthers, msg.value);
        
		 
        uint256 _buyPrice = buyPrice();
		
         
         
        uint tokens = msg.value * _buyPrice;

         
        require(tokens > 0);

		if ((time() >= (startDate + 15 days)) && (time() <= endDate)){
			uint leftTokens=sub(capTokens,add(totalTokens, tokens));
			leftTokens = (leftTokens>0)? leftTokens:0;
			uint bonusTokens = min(_userBonus[participant],min(tokens,leftTokens));
			
			 
			require(bonusTokens >= 0);
			
			tokens = add(tokens,bonusTokens);
        }
		
		 
		totalTokens = add(totalTokens, tokens);
        require(totalTokens <= capTokens);

		 
         
        uint ownerTokens = div(tokens,50)*19;

		 
        _totalSupply = add(_totalSupply, tokens);
		_totalSupply = add(_totalSupply, ownerTokens);
		
         
        _balances[participant] = add(_balances[participant], tokens);
		_balances[owner] = add(_balances[owner], ownerTokens);

		 
		if (time() < (startDate + 2 days)){
			uint bonus = div(tokens,2);
			_userBonus[participant] = add(_userBonus[participant], bonus);
        }
		
		 
        BoughtTokens(participant, msg.value, totalEthers, tokens, _buyPrice);
        Transfer(0x0, participant, tokens);
		Transfer(0x0, owner, ownerTokens);

    }

     
     
    function transfer(address _to, uint _amount) returns (bool success) {
         
        require((time() > endDate + 7 days ));
         
        return super.transfer(_to, _amount);
    }

     
     
     
    function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
         
        require((time() > endDate + 7 days ));
         
        return super.transferFrom(_from, _to, _amount);
    }

    function mint(uint256 _amount) onlyOwner {
        require((time() > endDate + 7 days ));
        require(_amount > 0);
        _balances[owner] = add(_balances[owner], _amount);
        _totalSupply = add(_totalSupply, _amount);
        Transfer(0x0, owner, _amount);
    }

    function burn(uint256 _amount) onlyOwner {
		require((time() > endDate + 7 days ));
        require(_amount > 0);
        _balances[owner] = sub(_balances[owner],_amount);
        _totalSupply = sub(_totalSupply,_amount);
		Transfer(owner, 0x0 , _amount);
    }
    
	function setCurs(uint8 _curs) onlyOwner {
        require(_curs > 0);
        curs = _curs;
    }

  	 
    function collect() onlyOwner {
		require(addrcnt.call.value(this.balance)(0));
		Collect(addrcnt,this.balance);
	}
}