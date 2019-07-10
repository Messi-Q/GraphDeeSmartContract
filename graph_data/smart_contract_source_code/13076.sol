pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC827 is ERC20 {
  function approveAndCall( address _spender, uint256 _value, bytes _data) public payable returns (bool);
  function transferAndCall( address _to, uint256 _value, bytes _data) public payable returns (bool);
  function transferFromAndCall(    address _from,    address _to,    uint256 _value,    bytes _data  )    public    payable    returns (bool);}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

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

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

contract Certifier {
    event Confirmed(address indexed who);
    event Revoked(address indexed who);
    function certified(address) public constant returns (bool);
    function get(address, string) public constant returns (bytes32);
    function getAddress(address, string) public constant returns (address);
    function getUint(address, string) public constant returns (uint);
}

contract Certifiable is Ownable {
    Certifier public certifier;
    event CertifierChanged(address indexed newCertifier);

    constructor(address _certifier) public {
        certifier = Certifier(_certifier);
    }

    function updateCertifier(address _address) public onlyOwner returns (bool success) {
        require(_address != address(0));
        emit CertifierChanged(_address);
        certifier = Certifier(_address);
        return true;
    }
}

contract KYCToken is Certifiable {
    mapping(address => bool) public kycPending;
    mapping(address => bool) public managers;

    event ManagerAdded(address indexed newManager);
    event ManagerRemoved(address indexed removedManager);

    modifier onlyManager() {
        require(managers[msg.sender] == true);
        _;
    }

    modifier isKnownCustomer(address _address) {
        require(!kycPending[_address] || certifier.certified(_address));
        if (kycPending[_address]) {
            kycPending[_address] = false;
        }
        _;
    }

    constructor(address _certifier) public Certifiable(_certifier)
    {

    }

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
        emit ManagerAdded(_address);
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
        emit ManagerRemoved(_address);
    }

}

contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

   
  function AllowanceCrowdsale(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

   
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract ERC827Token is ERC827, StandardToken {

   
  function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function transferFromAndCall(    address _from,    address _to,    uint256 _value,    bytes _data  )    public payable returns (bool)  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function increaseApprovalAndCall(address _spender, uint _addedValue, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function decreaseApprovalAndCall(address _spender, uint _subtractedValue, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call.value(msg.value)(_data));

    return true;
  }

}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract EDUCrowdsale is AllowanceCrowdsale, CappedCrowdsale, TimedCrowdsale, Ownable, Certifiable {
    using SafeMath for uint256;

    uint256 constant FIFTY_ETH = 50 * (10 ** 18);
    uint256 constant HUNDRED_AND_FIFTY_ETH = 150 * (10 ** 18);
    uint256 constant TWO_HUNDRED_AND_FIFTY_ETH = 250 * (10 ** 18);

    EDUToken public token;
    event TokenWalletChanged(address indexed newTokenWallet);
    event WalletChanged(address indexed newWallet);

    constructor(
        address _wallet,
        EDUToken _token,
        address _tokenWallet,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        address _certifier
    ) public
      Crowdsale(getCurrentRate(), _wallet, _token)
      AllowanceCrowdsale(_tokenWallet)
      CappedCrowdsale(_cap)
      TimedCrowdsale(_openingTime, _closingTime)
      Certifiable(_certifier)
    {
        token = _token;
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if (certifier.certified(_beneficiary)) {
            token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
        } else {
            token.delayedTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
        }
    }

     
    function getCurrentRate() public view returns (uint256) {
        if (block.timestamp < 1528156799) {          
            return 1050;
        } else if (block.timestamp < 1528718400) {   
            return 940;
        } else if (block.timestamp < 1529323200) {   
            return 865;
        } else if (block.timestamp < 1529928000) {   
            return 790;
        } else {
            return 750;
        }
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256)
    {
        uint256 currentRate = getCurrentRate();
        uint256 volumeBonus = _getVolumeBonus(currentRate, _weiAmount);
        return currentRate.mul(_weiAmount).add(volumeBonus);
    }

    function _getVolumeBonus(uint256 _currentRate, uint256 _weiAmount) internal view returns (uint256) {
        if (_weiAmount >= FIFTY_ETH) {
            if (_weiAmount >= HUNDRED_AND_FIFTY_ETH) {
                if (_weiAmount >= TWO_HUNDRED_AND_FIFTY_ETH) {
                    return _currentRate.mul(_weiAmount).mul(15).div(100);
                }
                return _currentRate.mul(_weiAmount).mul(10).div(100);
            }
            return _currentRate.mul(_weiAmount).mul(5).div(100);
        }
        return 0;
    }

    function changeTokenWallet(address _tokenWallet) external onlyOwner {
        require(_tokenWallet != address(0x0));
        tokenWallet = _tokenWallet;
        emit TokenWalletChanged(_tokenWallet);
    }

    function changeWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0x0));
        wallet = _wallet;
        emit WalletChanged(_wallet);
    }

}

contract EDUToken is BurnableToken, KYCToken, ERC827Token {
    using SafeMath for uint256;

    string public constant name = "EDU Token";
    string public constant symbol = "EDU";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 48000000 * (10 ** uint256(decimals));

    constructor(address _certifier) public KYCToken(_certifier) {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public isKnownCustomer(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isKnownCustomer(_from) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public isKnownCustomer(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isKnownCustomer(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isKnownCustomer(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function delayedTransferFrom(address _tokenWallet, address _to, uint256 _value) public onlyManager returns (bool) {
        transferFrom(_tokenWallet, _to, _value);
        kycPending[_to] = true;
    }

}