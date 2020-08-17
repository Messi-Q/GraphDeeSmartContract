pragma solidity ^0.4.24;
 
 
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract IMultiToken {
    function changeableTokenCount() external view returns(uint16 count);
    function tokens(uint256 i) public view returns(ERC20);
    function weights(address t) public view returns(uint256);
    function totalSupply() public view returns(uint256);
    function mint(address _to, uint256 _amount) public;
}


contract BancorBuyer {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public tokenBalances;  

    function sumWeightOfMultiToken(IMultiToken mtkn) public view returns(uint256 sumWeight) {
        for (uint i = mtkn.changeableTokenCount(); i > 0; i--) {
            sumWeight += mtkn.weights(mtkn.tokens(i - 1));
        }
    }

    function deposit(address _beneficiary, address[] _tokens, uint256[] _tokenValues) payable external {
        if (msg.value > 0) {
            balances[_beneficiary] = balances[_beneficiary].add(msg.value);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            uint256 tokenValue = _tokenValues[i];

            uint256 balance = token.balanceOf(this);
            token.transferFrom(msg.sender, this, tokenValue);
            require(token.balanceOf(this) == balance.add(tokenValue));
            tokenBalances[_beneficiary][token] = tokenBalances[_beneficiary][token].add(tokenValue);
        }
    }

    function withdraw(address _to, uint256 _value, address[] _tokens, uint256[] _tokenValues) external {
        if (_value > 0) {
            _to.transfer(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            uint256 tokenValue = _tokenValues[i];

            uint256 tokenBalance = token.balanceOf(this);
            token.transfer(_to, tokenValue);
            require(token.balanceOf(this) == tokenBalance.sub(tokenValue));
            tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(tokenValue);
        }
    }
    
    function buyOne(ERC20 token, address _exchange, uint256 _value, bytes _data) payable public {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        uint256 tokenBalance = token.balanceOf(this);
        require(_exchange.call.value(_value)(_data));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].add(token.balanceOf(this).sub(tokenBalance));
    }
    
    function buy1(address[] _tokens,  address[] _exchanges, uint256[] _values, bytes _data1) payable public {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        this.buyOne(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
    }
    
    function buy2(address[] _tokens, address[] _exchanges, uint256[] _values, bytes _data1, bytes _data2) payable public {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        this.buyOne(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        this.buyOne(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
    }
    
    function buy3(address[] _tokens, address[] _exchanges, uint256[] _values, bytes _data1, bytes _data2, bytes _data3) payable public {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        this.buyOne(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        this.buyOne(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        this.buyOne(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
    }
}