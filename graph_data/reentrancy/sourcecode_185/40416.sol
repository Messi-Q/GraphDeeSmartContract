contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (balancesVersions[version].balances[msg.sender] >= _value && balancesVersions[version].balances[_to] + _value > balancesVersions[version].balances[_to]) {
         
            balancesVersions[version].balances[msg.sender] -= _value;
            balancesVersions[version].balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balancesVersions[version].balances[_from] >= _value && allowedVersions[version].allowed[_from][msg.sender] >= _value && balancesVersions[version].balances[_to] + _value > balancesVersions[version].balances[_to]) {
         
            balancesVersions[version].balances[_to] += _value;
            balancesVersions[version].balances[_from] -= _value;
            allowedVersions[version].allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balancesVersions[version].balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowedVersions[version].allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowedVersions[version].allowed[_owner][_spender];
    }

     
    uint public version = 0;

    struct BalanceStruct {
      mapping(address => uint256) balances;
    }
    mapping(uint => BalanceStruct) balancesVersions;

    struct AllowedStruct {
      mapping (address => mapping (address => uint256)) allowed;
    }
    mapping(uint => AllowedStruct) allowedVersions;

    uint256 public totalSupply;

}

contract ReserveToken is StandardToken {
    address public minter;
    function setMinter() {
        if (minter==0x0000000000000000000000000000000000000000) {
            minter = msg.sender;
        }
    }
    modifier onlyMinter { if (msg.sender == minter) _; }
    function create(address account, uint amount) onlyMinter {
        balancesVersions[version].balances[account] += amount;
        totalSupply += amount;
    }
    function destroy(address account, uint amount) onlyMinter {
        if (balancesVersions[version].balances[account] < amount) throw;
        balancesVersions[version].balances[account] -= amount;
        totalSupply -= amount;
    }
    function reset() onlyMinter {
        version++;
        totalSupply = 0;
    }
}

contract EtherDelta {

  mapping (address => mapping (address => uint)) tokens;  
   
  mapping (bytes32 => uint) orderFills;
  address public feeAccount;
  uint public feeMake;  
  uint public feeTake;  

  event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  function EtherDelta(address feeAccount_, uint feeMake_, uint feeTake_) {
    feeAccount = feeAccount_;
    feeMake = feeMake_;
    feeTake = feeTake_;
  }

  function() {
    throw;
  }

  function deposit() {
    tokens[0][msg.sender] += msg.value;
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint amount) {
    if (msg.value>0) throw;
    if (tokens[0][msg.sender] < amount) throw;
    tokens[0][msg.sender] -= amount;
    if (!msg.sender.call.value(amount)()) throw;
    Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) {
     
    if (msg.value>0 || token==0) throw;
    if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
    tokens[token][msg.sender] += amount;
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawToken(address token, uint amount) {
    if (msg.value>0 || token==0) throw;
    if (tokens[token][msg.sender] < amount) throw;
    tokens[token][msg.sender] -= amount;
    if (!Token(token).transfer(msg.sender, amount)) throw;
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) constant returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
    if (msg.value>0) throw;
    Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
     
    if (msg.value>0) throw;
    bytes32 hash = sha256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      ecrecover(hash,v,r,s) == user &&
      block.number <= expires &&
      orderFills[hash] + amount <= amountGet &&
      tokens[tokenGet][msg.sender] >= amount &&
      tokens[tokenGive][user] >= amountGive * amount / amountGet
    )) throw;
    tokens[tokenGet][msg.sender] -= amount;
    tokens[tokenGet][user] += amount * ((1 ether) - feeMake) / (1 ether);
    tokens[tokenGet][feeAccount] += amount * feeMake / (1 ether);
    tokens[tokenGive][user] -= amountGive * amount / amountGet;
    tokens[tokenGive][msg.sender] += ((1 ether) - feeTake) * amountGive * amount / amountGet / (1 ether);
    tokens[tokenGive][feeAccount] += feeTake * amountGive * amount / amountGet / (1 ether);
    orderFills[hash] += amount;
    Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
  }

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
    bytes32 hash = sha256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      ecrecover(hash,v,r,s) == user &&
      block.number <= expires
    )) return 0;
    uint available1 = amountGet - orderFills[hash];
    uint available2 = tokens[tokenGive][user] * amountGet / amountGive;
    if (available1<available2) return available1;
    return available2;
  }
}