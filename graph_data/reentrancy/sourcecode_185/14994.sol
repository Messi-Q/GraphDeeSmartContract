pragma solidity ^0.4.23;

 
contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Created(uint time);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event AllowanceUsed(address indexed owner, address indexed spender, uint amount);

    constructor(string _name, string _symbol)
        public
    {
        name = _name;
        symbol = _symbol;
        emit Created(now);
    }

    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        address _spender = msg.sender;
        require(allowance[_from][_spender] >= _value);
        allowance[_from][_spender] -= _value;
        emit AllowanceUsed(_from, _spender, _value);
        return _transfer(_from, _to, _value);
    }

     
     
    function _transfer(address _from, address _to, uint _value)
        private
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

interface HasTokenFallback {
    function tokenFallback(address _from, uint256 _amount, bytes _data)
        external
        returns (bool success);
}
contract ERC667 is ERC20 {
    constructor(string _name, string _symbol)
        public
        ERC20(_name, _symbol)
    {}

    function transferAndCall(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        require(super.transfer(_to, _value));
        require(HasTokenFallback(_to).tokenFallback(msg.sender, _value, _data));
        return true;
    }
}

 
contract DividendToken is ERC667
{
     
    bool public isFrozen;

     
    address public comptroller = msg.sender;
    modifier onlyComptroller(){ require(msg.sender==comptroller); _; }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    uint constant POINTS_PER_WEI = 1e32;
    uint public dividendsTotal;
    uint public dividendsCollected;
    uint public totalPointsPerToken;
    uint public totalBurned;
    mapping (address => uint) public creditedPoints;
    mapping (address => uint) public lastPointsPerToken;

     
    event Frozen(uint time);
    event UnFrozen(uint time);
    event TokensMinted(uint time, address indexed account, uint amount, uint newTotalSupply);
    event TokensBurned(uint time, address indexed account, uint amount, uint newTotalSupply);
    event CollectedDividends(uint time, address indexed account, uint amount);
    event DividendReceived(uint time, address indexed sender, uint amount);

    constructor(string _name, string _symbol)
        public
        ERC667(_name, _symbol)
    {}

     
    function ()
        payable
        public
    {
        if (msg.value == 0) return;
         
         
        totalPointsPerToken += (msg.value * POINTS_PER_WEI) / totalSupply;
        dividendsTotal += msg.value;
        emit DividendReceived(now, msg.sender, msg.value);
    }

     
     
     
     
    function mint(address _to, uint _amount)
        onlyComptroller
        public
    {
        _updateCreditedPoints(_to);
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit TokensMinted(now, _to, _amount, totalSupply);
    }
    
     
    function burn(address _account, uint _amount)
        onlyComptroller
        public
    {
        require(balanceOf[_account] >= _amount);
        _updateCreditedPoints(_account);
        balanceOf[_account] -= _amount;
        totalSupply -= _amount;
        totalBurned += _amount;
        emit TokensBurned(now, _account, _amount, totalSupply);
    }

     
    function freeze(bool _isFrozen)
        onlyComptroller
        public
    {
        if (isFrozen == _isFrozen) return;
        isFrozen = _isFrozen;
        if (_isFrozen) emit Frozen(now);
        else emit UnFrozen(now);
    }

     
     
     
    
     
     
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {   
         
        require(!isFrozen);
        _updateCreditedPoints(msg.sender);
        _updateCreditedPoints(_to);
        return ERC20.transfer(_to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(!isFrozen);
        _updateCreditedPoints(_from);
        _updateCreditedPoints(_to);
        return ERC20.transferFrom(_from, _to, _value);
    }
    
     
     
    function transferAndCall(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        require(!isFrozen);
        _updateCreditedPoints(msg.sender);
        _updateCreditedPoints(_to);
        return ERC667.transferAndCall(_to, _value, _data);  
    }

     
    function collectOwedDividends() public returns (uint _amount) {
        _updateCreditedPoints(msg.sender);
        _amount = creditedPoints[msg.sender] / POINTS_PER_WEI;
        creditedPoints[msg.sender] = 0;
        dividendsCollected += _amount;
        emit CollectedDividends(now, msg.sender, _amount);
        require(msg.sender.call.value(_amount)());
    }

     
    function _updateCreditedPoints(address _account)
        private
    {
        creditedPoints[_account] += _getUncreditedPoints(_account);
        lastPointsPerToken[_account] = totalPointsPerToken;
    }

     
    function _getUncreditedPoints(address _account)
        private
        view
        returns (uint _amount)
    {
        uint _pointsPerToken = totalPointsPerToken - lastPointsPerToken[_account];
         
         
         
         
        return _pointsPerToken * balanceOf[_account];
    }


     
     
     
     
    function getOwedDividends(address _account)
        public
        constant
        returns (uint _amount)
    {
        return (_getUncreditedPoints(_account) + creditedPoints[_account])/POINTS_PER_WEI;
    }
}