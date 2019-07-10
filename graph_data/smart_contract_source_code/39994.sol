 

pragma solidity ^0.4.0;

contract Base
{
 

    string constant VERSION = "Base 0.1.1 \n";

 

    bool mutex;
    address public owner;

 

    event Log(string message);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

 

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

     
     
     
     
     
     
    modifier preventReentry() {
        if (mutex) throw;
        else mutex = true;
        _;
        delete mutex;
        return;
    }

     
     
     
    modifier noReentry() {
        if (mutex) throw;
        _;
    }

     
    modifier canEnter() {
        if (mutex) throw;
        _;
    }
    
 

    function Base() { owner = msg.sender; }

    function version() public constant returns (string) {
        return VERSION;
    }

    function contractBalance() public constant returns(uint) {
        return this.balance;
    }

     
    function changeOwner(address _newOwner)
        public onlyOwner returns (bool)
    {
        owner = _newOwner;
        ChangedOwner(msg.sender, owner);
        return true;
    }
    
    function safeSend(address _recipient, uint _ether) internal preventReentry()  returns (bool success_) {
        if(!_recipient.call.value(_ether)()) throw;
        success_ = true;
    }
}

 

 

pragma solidity ^0.4.0;

contract Math
{

 

    string constant VERSION = "Math 0.0.1 \n";
    uint constant NULL = 0;
    bool constant LT = false;
    bool constant GT = true;
     
    uint constant iTRUE = 1;
    uint constant iFALSE = 0;
    uint constant iPOS = 1;
    uint constant iZERO = 0;
    uint constant iNEG = uint(-1);


 

 
    function version() public constant returns (string)
    {
        return VERSION;
    }

    function assert(bool assertion) internal constant
    {
      if (!assertion) throw;
    }
    
     
     
     
    function cmp (uint a, uint b, bool _sym) internal constant returns (bool)
    {
        return (a!=b) && ((a < b) != _sym);
    }

     
     
     
    function cmpEq (uint a, uint b, bool _sym) internal constant returns (bool)
    {
        return (a==b) || ((a < b) != _sym);
    }
    
     
     
     
     
     
    function safeMul(uint a, uint b) internal constant returns (uint)
    {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeSub(uint a, uint b) internal constant returns (uint)
    {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal constant returns (uint)
    {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }
}

 


 

 

 
 

 
contract ERC20Interface
{
 

 
    string constant VERSION = "ERC20 0.2.3-o0ragman0o\nMath 0.0.1\nBase 0.1.1\n";

 
    uint public totalSupply;
    uint8 public decimalPlaces;
    string public name;
    string public symbol;
    
     
     
    mapping (address => uint) balance;
    
     
    mapping (address => mapping (address => uint)) public allowance;

 
     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value);

     
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value);

 

 

     

     
     

     
     

     
     

     
     

     
     

     
     

     
     

     
     
     
}

contract ERC20Token is Base, Math, ERC20Interface
{

 

 

 

 

 

    modifier isAvailable(uint _amount) {
        if (_amount > balance[msg.sender]) throw;
        _;
    }

    modifier isAllowed(address _from, uint _amount) {
        if (_amount > allowance[_from][msg.sender] ||
           _amount > balance[_from]) throw;
        _;        
    }

 

    function ERC20Token(
        uint _supply,
        uint8 _decimalPlaces,
        string _symbol,
        string _name)
    {
        totalSupply = _supply;
        decimalPlaces = _decimalPlaces;
        symbol = _symbol;
        name = _name;
        balance[msg.sender] = totalSupply;
    }
    
    function version() public constant returns(string) {
        return VERSION;
    }
    
    function balanceOf(address _addr)
        public
        constant
        returns (uint)
    {
        return balance[_addr];
    }

     
    function transfer(address _to, uint256 _value)
        external
        canEnter
        isAvailable(_value)
        returns (bool)
    {
        balance[msg.sender] = safeSub(balance[msg.sender], _value);
        balance[_to] = safeAdd(balance[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        external
        canEnter
        isAllowed(_from, _value)
        returns (bool)
    {
        balance[_from] = safeSub(balance[_from], _value);
        balance[_to] = safeAdd(balance[_to], _value);
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value)
        external
        canEnter
        returns (bool success)
    {
        if (balance[msg.sender] == 0) throw;
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

 


 

 

 
library LibCLLu {

    string constant VERSION = "LibCLLu 0.3.1";
    uint constant NULL = 0;
    uint constant HEAD = NULL;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (uint => mapping (bool => uint)) cll;
    }

     

    function version() internal constant returns (string) {
        return VERSION;
    }

     
    function exists(CLL storage self)
        internal
        constant returns (bool)
    {
        if (self.cll[HEAD][PREV] != HEAD || self.cll[HEAD][NEXT] != HEAD)
            return true;
    }
    
     
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        uint i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

     
    function getNode(CLL storage self, uint n)
        internal  constant returns (uint[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

     
    function step(CLL storage self, uint n, bool d)
        internal  constant returns (uint)
    {
        return self.cll[n][d];
    }

     
     
     
     
    function seek(CLL storage self, uint a, uint b, bool d)
        internal  constant returns (uint r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

     
    function stitch(CLL storage self, uint a, uint b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

     
    function insert (CLL storage self, uint a, uint b, bool d) internal  {
        uint c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, uint n) internal returns (uint) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, uint n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (uint) {
        return remove(self, step(self, HEAD, d));
    }
}

 
library LibCLLi {

    string constant VERSION = "LibCLLi 0.3.1";
    int constant NULL = 0;
    int constant HEAD = NULL;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (int => mapping (bool => int)) cll;
    }

     

    function version() internal constant returns (string) {
        return VERSION;
    }

     
    function exists(CLL storage self, int n) internal constant returns (bool) {
        if (self.cll[HEAD][PREV] != HEAD || self.cll[HEAD][NEXT] != HEAD)
            return true;
    }
     
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        int i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

     
    function getNode(CLL storage self, int n)
        internal  constant returns (int[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

     
    function step(CLL storage self, int n, bool d)
        internal  constant returns (int)
    {
        return self.cll[n][d];
    }

     
     
     
     
    function seek(CLL storage self, int a, int b, bool d)
        internal  constant returns (int r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

     
    function stitch(CLL storage self, int a, int b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

     
    function insert (CLL storage self, int a, int b, bool d) internal  {
        int c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, int n) internal returns (int) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, int n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (int) {
        return remove(self, step(self, HEAD, d));
    }
}


 

 

 

 
 
 
 

contract ITTInterface
{

    using LibCLLu for LibCLLu.CLL;

 

    string constant VERSION = "ITT 0.3.6\nERC20 0.2.3-o0ragman0o\nMath 0.0.1\nBase 0.1.1\n";
    uint constant HEAD = 0;
    uint constant MINNUM = uint(1);
     
    uint constant MAXNUM = 2**128;
    uint constant MINPRICE = uint(1);
    uint constant NEG = uint(-1);  
    bool constant PREV = false;
    bool constant NEXT = true;
    bool constant BID = false;
    bool constant ASK = true;

     
    uint constant MINGAS = 100000;

     
     
     
    struct TradeMessage {
        bool make;
        bool side;
        uint price;
        uint tradeAmount;
        uint balance;
        uint etherBalance;
    }

 

     
    bool public trading;

     
    mapping (address => uint) etherBalance;

     
     
     
     
    mapping (uint => LibCLLu.CLL) orderFIFOs;
    
     
     
     
    mapping (bytes32 => uint) amounts;

     
    LibCLLu.CLL priceBook = orderFIFOs[0];


 

     
    event Ask (uint indexed price, uint amount, address indexed trader);

     
    event Bid (uint indexed price, uint amount, address indexed trader);

     
    event Sale (uint indexed price, uint amount, address indexed buyer, address indexed seller);

     
    event Trading(bool trading);

 

     
    function spread(bool _side) public constant returns(uint);
    
     
     
     
    function getAmount(uint _price, address _trader) 
        public constant returns(uint);

     
     
    function getPriceVolume(uint _price) public constant returns (uint);

     
     
     
    function getBook() public constant returns (uint[]);

 

     
     
     
     
    function buy (uint _bidPrice, uint _amount, bool _make)
        payable returns (bool);

     
     
     
     
    function sell (uint _askPrice, uint _amount, bool _make)
        external returns (bool);

     
     
    function withdraw(uint _ether)
        external returns (bool success_);

     
     
    function cancel(uint _price) 
        external returns (bool);

     
     
    function setTrading(bool _trading) 
        external returns (bool);
}


  

contract ITT is ERC20Token, ITTInterface
{

 

 

     
    modifier isTrading() {
        if (!trading) throw;
        _;
    }

     
    modifier isValidBuy(uint _bidPrice, uint _amount) {
        if ((etherBalance[msg.sender] + msg.value) < (_amount * _bidPrice) ||
            _amount == 0 || _amount > totalSupply ||
            _bidPrice <= MINPRICE || _bidPrice >= MAXNUM) throw;  
        _;
    }

     
    modifier isValidSell(uint _askPrice, uint _amount) {
        if (_amount > balance[msg.sender] || _amount == 0 ||
            _askPrice < MINPRICE || _askPrice > MAXNUM) throw;
        _;
    }
    
     
    modifier hasEther(address _member, uint _ether) {
        if (etherBalance[_member] < _ether) throw;
        _;
    }

     
    modifier hasBalance(address _member, uint _amount) {
        if (balance[_member] < _amount) throw;
        _;
    }

 

    function ITT(
        uint _totalSupply,
        uint8 _decimalPlaces,
        string _symbol,
        string _name
        )
            ERC20Token(
                _totalSupply,
                _decimalPlaces,
                _symbol,
                _name
                )
    {
         
        priceBook.cll[HEAD][PREV] = MINPRICE;
        priceBook.cll[MINPRICE][PREV] = MAXNUM;
        priceBook.cll[HEAD][NEXT] = MAXNUM;
        priceBook.cll[MAXNUM][NEXT] = MINPRICE;
        trading = true;
        balance[owner] = totalSupply;
    }

 

    function version() public constant returns(string) {
        return VERSION;
    }

    function etherBalanceOf(address _addr) public constant returns (uint) {
        return etherBalance[_addr];
    }

    function spread(bool _side) public constant returns(uint) {
        return priceBook.step(HEAD, _side);
    }

    function getAmount(uint _price, address _trader) 
        public constant returns(uint) {
        return amounts[sha3(_price, _trader)];
    }

    function sizeOf(uint l) constant returns (uint s) {
        if(l == 0) return priceBook.sizeOf();
        return orderFIFOs[l].sizeOf();
    }
    
    function getPriceVolume(uint _price) public constant returns (uint v_)
    {
        uint n = orderFIFOs[_price].step(HEAD,NEXT);
        while (n != HEAD) { 
            v_ += amounts[sha3(_price, address(n))];
            n = orderFIFOs[_price].step(n, NEXT);
        }
        return;
    }

    function getBook() public constant returns (uint[])
    {
        uint i; 
        uint p = priceBook.step(MINNUM, NEXT);
        uint[] memory volumes = new uint[](priceBook.sizeOf() * 2 - 2);
        while (p < MAXNUM) {
            volumes[i++] = p;
            volumes[i++] = getPriceVolume(p);
            p = priceBook.step(p, NEXT);
        }
        return volumes; 
    }
    
    function numOrdersOf(address _addr) public constant returns (uint)
    {
        uint c;
        uint p = MINNUM;
        while (p < MAXNUM) {
            if (amounts[sha3(p, _addr)] > 0) c++;
            p = priceBook.step(p, NEXT);
        }
        return c;
    }
    
    function getOpenOrdersOf(address _addr) public constant returns (uint[])
    {
        uint i;
        uint c;
        uint p = MINNUM;
        uint[] memory open = new uint[](numOrdersOf(_addr)*2);
        p = MINNUM;
        while (p < MAXNUM) {
            if (amounts[sha3(p, _addr)] > 0) {
                open[i++] = p;
                open[i++] = amounts[sha3(p, _addr)];
            }
            p = priceBook.step(p, NEXT);
        }
        return open;
    }

    function getNode(uint _list, uint _node) public constant returns(uint[2])
    {
        return [orderFIFOs[_list].cll[_node][PREV], 
            orderFIFOs[_list].cll[_node][NEXT]];
    }
    
 

 
 
 
 
 
 

    function buy (uint _bidPrice, uint _amount, bool _make)
        payable
        canEnter
        isTrading
        isValidBuy(_bidPrice, _amount)
        returns (bool)
    {
        trade(_bidPrice, _amount, BID, _make);
        return true;
    }

    function sell (uint _askPrice, uint _amount, bool _make)
        external
        canEnter
        isTrading
        isValidSell(_askPrice, _amount)
        returns (bool)
    {
        trade(_askPrice, _amount, ASK, _make);
        return true;
    }

    function withdraw(uint _ether) external canEnter  hasEther(msg.sender, _ether) returns (bool success_) {
        etherBalance[msg.sender] -= _ether;
        safeSend(msg.sender, _ether);
        success_ = true;
    }

    function cancel(uint _price)
        external
        canEnter
        returns (bool)
    {
        TradeMessage memory tmsg;
        tmsg.price = _price;
        tmsg.balance = balance[msg.sender];
        tmsg.etherBalance = etherBalance[msg.sender];
        cancelIntl(tmsg);
        balance[msg.sender] = tmsg.balance;
        etherBalance[msg.sender] = tmsg.etherBalance;
        return true;
    }
    
    function setTrading(bool _trading)
        external
        onlyOwner
        canEnter
        returns (bool)
    {
        trading = _trading;
        Trading(true);
        return true;
    }

 

 

    function trade (uint _price, uint _amount, bool _side, bool _make) internal {
        TradeMessage memory tmsg;
        tmsg.price = _price;
        tmsg.tradeAmount = _amount;
        tmsg.side = _side;
        tmsg.make = _make;
        
         
        tmsg.balance  = balance[msg.sender];
        tmsg.etherBalance = etherBalance[msg.sender] + msg.value;

        take(tmsg);
        make(tmsg);
        
        balance[msg.sender] = tmsg.balance;
        etherBalance[msg.sender] = tmsg.etherBalance;
    }
    
    function take (TradeMessage tmsg)
        internal
    {
        address maker;
        bytes32 orderHash;
        uint takeAmount;
        uint takeEther;
         
        uint sign = tmsg.side ? uint(1) : uint(-1);
        uint bestPrice = spread(!tmsg.side);

         
        while (
            tmsg.tradeAmount > 0 &&
            cmpEq(tmsg.price, bestPrice, !tmsg.side) && 
            msg.gas > MINGAS
        )
        {
            maker = address(orderFIFOs[bestPrice].step(HEAD, NEXT));
            orderHash = sha3(bestPrice, maker);
            if (tmsg.tradeAmount < amounts[orderHash]) {
                 
                amounts[orderHash] = safeSub(amounts[orderHash], tmsg.tradeAmount);
                takeAmount = tmsg.tradeAmount;
                tmsg.tradeAmount = 0;
            } else {
                 
                takeAmount = amounts[orderHash];
                tmsg.tradeAmount = safeSub(tmsg.tradeAmount, takeAmount);
                closeOrder(bestPrice, maker);
            }
            takeEther = safeMul(bestPrice, takeAmount);
             
             
            tmsg.etherBalance += takeEther * sign;
            tmsg.balance -= takeAmount * sign;
            if (tmsg.side) {
                 
                if (msg.sender == maker) {
                     
                    tmsg.balance += takeAmount;
                } else {
                    balance[maker] += takeAmount;
                }
            } else {
                 
                if (msg.sender == maker) {
                     
                    tmsg.etherBalance += takeEther;
                } else {                
                    etherBalance[maker] += takeEther;
                }
            }
             
            bestPrice = spread(!tmsg.side);
            Sale (bestPrice, takeAmount, msg.sender, maker);
        }
    }

    function make(TradeMessage tmsg)
        internal
    {
        bytes32 orderHash;
        if (tmsg.tradeAmount == 0 || !tmsg.make || msg.gas < MINGAS) return;
        orderHash = sha3(tmsg.price, msg.sender);
        if (amounts[orderHash] != 0) {
             
            cancelIntl(tmsg);
        }
        if (!orderFIFOs[tmsg.price].exists()) {
             
            priceBook.insert(
                priceBook.seek(HEAD, tmsg.price, tmsg.side),
                tmsg.price, !tmsg.side);
        }

        amounts[orderHash] = tmsg.tradeAmount;
        orderFIFOs[tmsg.price].push(uint(msg.sender), PREV); 

        if (tmsg.side) {
            tmsg.balance -= tmsg.tradeAmount;
            Ask (tmsg.price, tmsg.tradeAmount, msg.sender);
        } else {
            tmsg.etherBalance -= tmsg.tradeAmount * tmsg.price;
            Bid (tmsg.price, tmsg.tradeAmount, msg.sender);
        }
    }

    function cancelIntl(TradeMessage tmsg) internal {
        uint amount = amounts[sha3(tmsg.price, msg.sender)];
        if (amount == 0) return;
        if (tmsg.price > spread(BID)) tmsg.balance += amount;  
        else tmsg.etherBalance += tmsg.price * amount;  
        closeOrder(tmsg.price, msg.sender);
    }

    function closeOrder(uint _price, address _trader) internal {
        orderFIFOs[_price].remove(uint(_trader));
        if (!orderFIFOs[_price].exists())  {
            priceBook.remove(_price);
        }
        delete amounts[sha3(_price, _trader)];
    }
}