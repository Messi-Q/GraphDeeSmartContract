pragma solidity ^ 0.4.21;

pragma solidity ^0.4.10;

 
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
pragma solidity ^0.4.10;

interface ERC20 {
  function balanceOf(address who) view returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  function allowance(address owner, address spender) view returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.4.10;

interface ERC223 {
    function transfer(address to, uint value, bytes data) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
pragma solidity ^0.4.10;

contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

pragma solidity ^0.4.21;

 
contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	 
	function Ownable()public {
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

pragma solidity ^0.4.21;

 
contract RefundVault is Ownable {
	using SafeMath for uint256;

	enum State {
		Active,
		Refunding,
		Closed
	}

	mapping(address => uint256) public deposited;
	address public wallet;
	State public state;

	event Closed();
	event RefundsEnabled();
	event Refunded(address indexed beneficiary, uint256 weiAmount);

	 
	function RefundVault(address _wallet) public {
		require(_wallet != address(0));
		wallet = _wallet;
		state = State.Active;
	}

	 
	function deposit(address investor) onlyOwner public payable {
		require(state == State.Active);
		deposited[investor] = deposited[investor].add(msg.value);
	}

	function close() onlyOwner public {
		require(state == State.Active);
		state = State.Closed;
		emit Closed();
		wallet.transfer(address(this).balance);
	}

	function enableRefunds() onlyOwner public {
		require(state == State.Active);
		state = State.Refunding;
		emit RefundsEnabled();
	}

	 
	function refund(address investor) public {
		require(state == State.Refunding);
		uint256 depositedValue = deposited[investor];
		deposited[investor] = 0;
		investor.transfer(depositedValue);
		emit Refunded(investor, depositedValue);
	}
}
pragma solidity ^0.4.21;

 
contract BonusScheme is Ownable {
	using SafeMath for uint256;

	 
	uint256 startOfFirstBonus = 1526021400;
	uint256 endOfFirstBonus = (startOfFirstBonus - 1) + 5 minutes;	
	uint256 startOfSecondBonus = (startOfFirstBonus + 1) + 5 minutes;
	uint256 endOfSecondBonus = (startOfSecondBonus - 1) + 5 minutes;
	uint256 startOfThirdBonus = (startOfSecondBonus + 1) + 5 minutes;
	uint256 endOfThirdBonus = (startOfThirdBonus - 1) + 5 minutes;
	uint256 startOfFourthBonus = (startOfThirdBonus + 1) + 5 minutes;
	uint256 endOfFourthBonus = (startOfFourthBonus - 1) + 5 minutes;
	uint256 startOfFifthBonus = (startOfFourthBonus + 1) + 5 minutes;
	uint256 endOfFifthBonus = (startOfFifthBonus - 1) + 5 minutes;
	
	 
	uint256 firstBonus = 35;
	uint256 secondBonus = 30;
	uint256 thirdBonus = 20;
	uint256 fourthBonus = 10;
	uint256 fifthBonus = 5;

	event BonusCalculated(uint256 tokenAmount);

    function BonusScheme() public {
        
    }

	 
	function getBonusTokens(uint256 _tokenAmount)onlyOwner public returns(uint256) {
		if (block.timestamp >= startOfFirstBonus && block.timestamp <= endOfFirstBonus) {
			_tokenAmount = _tokenAmount.mul(firstBonus).div(100);
		} else if (block.timestamp >= startOfSecondBonus && block.timestamp <= endOfSecondBonus) {
			_tokenAmount = _tokenAmount.mul(secondBonus).div(100);
		} else if (block.timestamp >= startOfThirdBonus && block.timestamp <= endOfThirdBonus) {
			_tokenAmount = _tokenAmount.mul(thirdBonus).div(100);
		} else if (block.timestamp >= startOfFourthBonus && block.timestamp <= endOfFourthBonus) {
			_tokenAmount = _tokenAmount.mul(fourthBonus).div(100);
		} else if (block.timestamp >= startOfFifthBonus && block.timestamp <= endOfFifthBonus) {
			_tokenAmount = _tokenAmount.mul(fifthBonus).div(100);
		} else _tokenAmount=0;
		emit BonusCalculated(_tokenAmount);
		return _tokenAmount;
	}
}

contract StandardToken is ERC20, ERC223, Ownable {
	using SafeMath for uint;

	string internal _name;
	string internal _symbol;
	uint8 internal _decimals;
	uint256 internal _totalSupply;
	uint256 internal _bonusSupply;

	uint256 public ethRate;  
	uint256 public min_contribution;  
	uint256 public totalWeiRaised;  
	uint public tokensSold;  

	uint public softCap;  
	uint public start;  
	uint public end;  
	bool public crowdsaleClosed;  
	RefundVault public vault;  
	BonusScheme public bonusScheme;  

	address public fundsWallet;  

	mapping(address => bool)public frozenAccount;
	mapping(address => uint256)internal balances;
	mapping(address => mapping(address => uint256))internal allowed;

	 
	event Burn(address indexed burner, uint256 value);
	event FrozenFunds(address target, bool frozen);
	event Finalized();
	event BonusSent(address indexed from, address indexed to, uint256 boughtTokens, uint256 bonusTokens);

	 
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	 
	 
	 
	function StandardToken() public {
		_symbol = "AmTC1";
		_name = "AmTokenTestCase1";
		_decimals = 5;
		_totalSupply = 1100000 * (10 ** uint256(_decimals));
		 
		 
		_bonusSupply = _totalSupply * 17 / 100;  
		
		fundsWallet = msg.sender;  
		vault = new RefundVault(fundsWallet);
		bonusScheme = new BonusScheme();

		 
		balances[msg.sender] = _totalSupply.sub(_bonusSupply);
		balances[bonusScheme] = _bonusSupply;
		ethRate = 40000000;  
		min_contribution = 1 ether / (10**11);  
		totalWeiRaised = 0;
		tokensSold = 0;
		softCap = 20000 * 10 ** uint(_decimals);
		start = 1526021100;
		end = 1526023500;
		crowdsaleClosed = false;
	}

	modifier beforeICO() {
		require(block.timestamp <= start);
		_;
	}
	
	modifier afterDeadline() {
		require(block.timestamp > end);
		_;
	}

	function name()	public	view	returns(string) {
		return _name;
	}

	function symbol()	public	view	returns(string) {
		return _symbol;
	}

	function decimals()	public	view	returns(uint8) {
		return _decimals;
	}

	function totalSupply() public	view returns(uint256) {
		return _totalSupply;
	}

	 
	 
	 

	 
	function () external payable {
		buyTokens(msg.sender);
	}

	 
	 
	 
	function buyTokens(address _beneficiary) public payable {
		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);
		uint256 tokens = _getTokenAmount(weiAmount);  
		require(balances[this] > tokens);  

		totalWeiRaised = totalWeiRaised.add(weiAmount);  
		tokensSold = tokensSold.add(tokens);  

		_processPurchase(_beneficiary, tokens);
		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
		_processBonus(_beneficiary, tokens);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);

		 

	}

	 
	 
	 

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
		require(_beneficiary != address(0));
		require(_weiAmount >= min_contribution);
		require(!crowdsaleClosed && block.timestamp >= start && block.timestamp <= end);
	}

	 
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
		 
	}

	 
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
		this.transfer(_beneficiary, _tokenAmount);
	}

	 
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	 
	function _processBonus(address _beneficiary, uint256 _tokenAmount) internal {
		uint256 bonusTokens = bonusScheme.getBonusTokens(_tokenAmount);  
		if (balances[bonusScheme] < bonusTokens) {  
			bonusTokens = balances[bonusScheme];
		}
		if (bonusTokens > 0) {  
			balances[bonusScheme] = balances[bonusScheme].sub(bonusTokens);
			balances[_beneficiary] = balances[_beneficiary].add(bonusTokens);
			emit Transfer(address(bonusScheme), _beneficiary, bonusTokens);
			emit BonusSent(address(bonusScheme), _beneficiary, _tokenAmount, bonusTokens);
			tokensSold = tokensSold.add(bonusTokens);  
		}
	}

	 
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
		 
	}

	 
	function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
		_weiAmount = _weiAmount.mul(ethRate);
		return _weiAmount.div(10 ** uint(18 - _decimals));  
	}

	 
	function _forwardFunds()internal {
		vault.deposit.value(msg.value)(msg.sender);  
	}

	 
	 
	 
	function transfer(address _to, uint256 _value) public returns(bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(!frozenAccount[msg.sender]);  
		require(!frozenAccount[_to]);  
		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns(uint256 balance) {
		return balances[_owner];
	}

	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
		require(_to != address(0));
		require(!frozenAccount[_from]);  
		require(!frozenAccount[_to]);  
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value)public returns(bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns(uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns(bool success) {
		require(!frozenAccount[msg.sender]);  
		require(!frozenAccount[_to]);  
		if (isContract(_to)) {
			return transferToContractWithCustomFallback(_to, _value, _data, _custom_fallback);
		} else {
			return transferToAddress(_to, _value, _data);
		}
	}

	 
	function transfer(address _to, uint _value, bytes _data) public returns(bool) {
		require(!frozenAccount[msg.sender]);  
		require(!frozenAccount[_to]);  
		if (isContract(_to)) {
			return transferToContract(_to, _value, _data);
		} else {
			return transferToAddress(_to, _value, _data);
		}
		 
	}

	function isContract(address _addr) private view returns(bool is_contract) {
		uint length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	 
	function transferToAddress(address _to, uint _value, bytes _data) private returns(bool success) {
		require(balanceOf(msg.sender) > _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	 
	function transferToContract(address _to, uint _value, bytes _data) private returns(bool success) {
		require(balanceOf(msg.sender) > _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	 
	function transferToContractWithCustomFallback(address _to, uint _value, bytes _data, string _custom_fallback) private returns(bool success) {
		require(balanceOf(msg.sender) > _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function setPreICOSoldAmount(uint256 _soldTokens, uint256 _raisedWei) onlyOwner beforeICO public {
		tokensSold = tokensSold.add(_soldTokens);
		totalWeiRaised = totalWeiRaised.add(_raisedWei);
	}
	
	 
	 
	 
	function freezeAccount(address target, bool freeze) onlyOwner public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	 
	function burn(uint256 _value) onlyOwner public returns(bool success) {
		require(balances[msg.sender] >= _value);  
		balances[msg.sender] = balances[msg.sender].sub(_value);  
		_totalSupply = _totalSupply.sub(_value);  
		emit Burn(msg.sender, _value);
		emit Transfer(msg.sender, address(0), _value);
		return true;
	}

	 

	 
	function withdrawTokens() onlyOwner public returns(bool) {
		require(this.transfer(owner, balances[this]));
		uint256 bonusTokens = balances[address(bonusScheme)];
		balances[address(bonusScheme)] = 0;
		if (bonusTokens > 0) {  
			balances[owner] = balances[owner].add(bonusTokens);
			emit Transfer(address(bonusScheme), owner, bonusTokens);
		}
		return true;
	}

	 
	function transferAnyERC20Token(address _tokenAddress, uint256 _amount) onlyOwner public returns(bool success) {
		return ERC20(_tokenAddress).transfer(owner, _amount);
	}

	 
	function claimRefund() public {
		require(crowdsaleClosed);
		require(!goalReached());

		vault.refund(msg.sender);
	}

	 
	function goalReached() public view returns(bool) {
		return tokensSold >= softCap;
	}

	 
	function finalization() internal {
		if (goalReached()) {
			vault.close();
		} else {
			vault.enableRefunds();
		}
	}

	 
	function finalize() onlyOwner afterDeadline public {
		require(!crowdsaleClosed);

		finalization();
		emit Finalized();
		withdrawTokens();

		crowdsaleClosed = true;
	}

}