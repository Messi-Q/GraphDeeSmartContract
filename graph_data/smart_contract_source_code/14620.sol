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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract TokensGate is MintableToken {
  event Burn(address indexed burner, uint256 value);

  string public constant name = "TokensGate";
  string public constant symbol = "TGC";
  uint8 public constant decimals = 18;
  
  bool public AllowTransferGlobal = false;
  bool public AllowTransferLocal = false;
  bool public AllowTransferExternal = false;
  
  mapping(address => uint256) public Whitelist;
  mapping(address => uint256) public LockupList;
  mapping(address => bool) public WildcardList;
  mapping(address => bool) public Managers;
    
  function allowTransfer(address _from, address _to) public view returns (bool) {
    if (WildcardList[_from])
      return true;
      
    if (LockupList[_from] > now)
      return false;
    
    if (!AllowTransferGlobal) {
        if (AllowTransferLocal && Whitelist[_from] != 0 && Whitelist[_to] != 0 && Whitelist[_from] < now && Whitelist[_to] < now)
            return true;
            
        if (AllowTransferExternal && Whitelist[_from] != 0 && Whitelist[_from] < now)
            return true;
        
        return false;
    }
      
    return true;
  }
    
  function allowManager() public view returns (bool) {
    if (msg.sender == owner)
      return true;
    
    if (Managers[msg.sender])
      return true;
      
    return false;
  }
    
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(allowTransfer(msg.sender, _to));
      
    return super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(allowTransfer(_from, _to));
      
    return super.transferFrom(_from, _to, _value);
  }
    
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) < 1000000000000000000000000000);

    return super.mint(_to, _amount);
  }
    
  function burn(address _burner, uint256 _value) onlyOwner public {
    require(_value <= balances[_burner]);

    balances[_burner] = balances[_burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_burner, _value);
    Transfer(_burner, address(0), _value);
  }
  
  function setManager(address _manager, bool _status) onlyOwner public {
    Managers[_manager] = _status;
  }
  
  function setAllowTransferGlobal(bool _status) public {
    require(allowManager());
      
    AllowTransferGlobal = _status;
  }
  
  function setAllowTransferLocal(bool _status) public {
    require(allowManager());
    
    AllowTransferLocal = _status;
  }
  
  function setAllowTransferExternal(bool _status) public {
    require(allowManager());
    
    AllowTransferExternal = _status;
  }
    
  function setWhitelist(address _address, uint256 _date) public {
    require(allowManager());
    
    Whitelist[_address] = _date;
  }
  
  function setLockupList(address _address, uint256 _date) public {
    require(allowManager());
    
    LockupList[_address] = _date;
  }
  
  function setWildcardList(address _address, bool _status) public {
    require(allowManager());
      
    WildcardList[_address] = _status;
  }
  
  function transferTokens(address walletToTransfer, address tokenAddress, uint256 tokenAmount) onlyOwner payable public {
    ERC20 erc20 = ERC20(tokenAddress);
    erc20.transfer(walletToTransfer, tokenAmount);
  }
  
  function transferEth(address walletToTransfer, uint256 weiAmount) onlyOwner payable public {
    require(walletToTransfer != address(0));
    require(address(this).balance >= weiAmount);
    require(address(this) != walletToTransfer);

    require(walletToTransfer.call.value(weiAmount)());
  }
}