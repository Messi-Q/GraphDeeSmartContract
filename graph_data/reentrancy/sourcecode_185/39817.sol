pragma solidity ^0.4.0;

contract SafeMath {
   

  function safeMul(uint256 a, uint256 b) internal returns (uint256 c) {
    c = a * b;
    assert(a == 0 || c / a == b);
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256 c) {
    assert(b <= a);
    c = a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256 c) {
    c = a + b;
    assert(c>=a && c>=b);
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Token {
   
  function totalSupply() constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract ValueToken is SafeMath,Token{
    
    string name = "Value";
    uint decimals = 0;
    
    uint256 supplyNow = 0; 
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() constant returns (uint256 totalSupply){
        return supplyNow;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success){
        if (balanceOf(msg.sender) >= _value) {
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
        
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = safeAdd(balanceOf(_to), _value);
            balances[_from] = safeSub(balanceOf(_from), _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success){
        if(balances[msg.sender] >= _value){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
        } else { return false; }
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    function createValue(address _owner, uint256 _value) internal returns (bool success){
        balances[_owner] = safeAdd(balances[_owner], _value);
        supplyNow = safeAdd(supplyNow, _value);
        Mint(_owner, _value);
    }
    
    function destroyValue(address _owner, uint256 _value) internal returns (bool success){
        balances[_owner] = safeSub(balances[_owner], _value);
        supplyNow = safeSub(supplyNow, _value);
        Burn(_owner, _value);
    }
    
    event Mint(address indexed _owner, uint256 _value);
    
    event Burn(address indexed _owner, uint256 _value);
    
}

 
contract ValueTrader is SafeMath,ValueToken{
    
    function () payable {
         
         
    }
    
     
    struct TokenData {
        bool isValid;  
        uint256 basePrice;  
        uint256 baseLiquidity;  
        uint256 priceScaleFactor;  
        bool hasDividend;
        address divContractAddress;
        bytes divData;
    }
    
    address owner;
    address etherContract;
    uint256 tradeCoefficient;  
    mapping (address => TokenData) tokenManage;
    bool public burning = false;  
    bool public draining = false;  
    
    modifier owned(){
        assert(msg.sender == owner);
        _;
    }
    
    modifier burnBlock(){
        assert(!burning);
        _;
    }
    
    modifier drainBlock(){
        assert(!draining);
        _;
    }
    
     
    function toggleDrain() burnBlock owned {
        draining = !draining;
    }
    
    function toggleBurn() owned {
        assert(draining);
        assert(balanceOf(owner) == supplyNow);
        burning = !burning;
    }
    
    function die() owned burnBlock{
         
        selfdestruct(owner);
    }
    
    function validateToken(address token_, uint256 bP_, uint256 bL_, uint256 pF_) owned {
        
        tokenManage[token_].isValid = true;
        tokenManage[token_].basePrice = bP_;
        tokenManage[token_].baseLiquidity = bL_;
        tokenManage[token_].priceScaleFactor = pF_;
        
    }
    
    function configureTokenDividend(address token_, bool hD_, address dA_, bytes dD_) owned {
    
        tokenManage[token_].hasDividend = hD_;
        tokenManage[token_].divContractAddress = dA_;
        tokenManage[token_].divData = dD_;
    }
    
    function callDividend(address token_) owned {
         
         
         
         
        assert(tokenManage[token_].hasDividend);
        assert(tokenManage[token_].divContractAddress.call.value(0)(tokenManage[token_].divData));
    }
    
    function invalidateToken(address token_) owned {
        tokenManage[token_].isValid = false;
    }
    
    function changeOwner(address owner_) owned {
        owner = owner_;
    }
    
    function changeFee(uint256 tradeFee) owned {
        tradeCoefficient = tradeFee;
    }
    
    function changeEtherContract(address eC) owned {
        etherContract = eC;
    }
    
    event Buy(address tokenAddress, address buyer, uint256 amount, uint256 remaining);
    event Sell(address tokenAddress, address buyer, uint256 amount, uint256 remaining);
    event Trade(address fromTokAddress, address toTokAddress, address buyer, uint256 amount);

    function ValueTrader(){
        owner = msg.sender;
        burning = false;
        draining = false;
    }
    
    
    
    function valueWithFee(uint256 tempValue) internal returns (uint256 doneValue){
        doneValue = safeMul(tempValue,tradeCoefficient)/10000;
        if(tradeCoefficient < 10000){
             
            createValue(owner,safeSub(tempValue,doneValue));
        }
    }
    
    function currentPrice(address token) constant returns (uint256 price){
        if(draining){
            price = 1;
        } else {
        assert(tokenManage[token].isValid);
        uint256 basePrice = tokenManage[token].basePrice;
        uint256 baseLiquidity = tokenManage[token].baseLiquidity;
        uint256 priceScaleFactor = tokenManage[token].priceScaleFactor;
        uint256 currentLiquidity;
        if(token == etherContract){
            currentLiquidity = this.balance;
        }else{
            currentLiquidity = Token(token).balanceOf(this);
        }
        price = safeAdd(basePrice,safeMul(priceScaleFactor,baseLiquidity/currentLiquidity));
        }
    }
    
    function currentLiquidity(address token) constant returns (uint256 liquidity){
        liquidity = Token(token).balanceOf(this);
    }
    
    function valueToToken(address token, uint256 amount) constant internal returns (uint256 value){
        value = amount/currentPrice(token);
        assert(value != 0);
    }
    
    function tokenToValue(address token, uint256 amount) constant internal returns (uint256 value){
        value = safeMul(amount,currentPrice(token));
    }
    
    function sellToken(address token, uint256 amount) drainBlock {
     
        assert(verifiedTransferFrom(token,msg.sender,amount));
        assert(createValue(msg.sender, tokenToValue(token,amount)));
        Sell(token, msg.sender, amount, balances[msg.sender]);
    }

    function buyToken(address token, uint256 amount) {
        assert(!(valueToToken(token,balances[msg.sender]) < amount));
        assert(destroyValue(msg.sender, tokenToValue(token,amount)));
        assert(Token(token).transfer(msg.sender, amount));
        Buy(token, msg.sender, amount, balances[msg.sender]);
    }
    
    function sellEther() payable drainBlock {
        assert(createValue(msg.sender, tokenToValue(etherContract,msg.value)));
        Sell(etherContract, msg.sender, msg.value, balances[msg.sender]);
    }
    
    function buyEther(uint256 amount) {
        assert(valueToToken(etherContract,balances[msg.sender]) >= amount);
        assert(destroyValue(msg.sender, tokenToValue(etherContract,amount)));
        assert(msg.sender.call.value(amount)());
        Buy(etherContract, msg.sender, amount, balances[msg.sender]);
    }
    
     
    function quickTrade(address tokenFrom, address tokenTo, uint256 input) payable drainBlock {
         
        uint256 inValue;
        uint256 tempInValue = safeAdd(tokenToValue(etherContract,msg.value),
        tokenToValue(tokenFrom,input));
        inValue = valueWithFee(tempInValue);
        uint256 outValue = valueToToken(tokenTo,inValue);
        assert(verifiedTransferFrom(tokenFrom,msg.sender,input));
        if (tokenTo == etherContract){
          assert(msg.sender.call.value(outValue)());  
        } else assert(Token(tokenTo).transfer(msg.sender, outValue));
        Trade(tokenFrom, tokenTo, msg.sender, inValue);
    }
    
    function verifiedTransferFrom(address tokenFrom, address senderAdd, uint256 amount) internal returns (bool success){
    uint256 balanceBefore = Token(tokenFrom).balanceOf(this);
    success = Token(tokenFrom).transferFrom(senderAdd, this, amount);
    uint256 balanceAfter = Token(tokenFrom).balanceOf(this);
    assert((safeSub(balanceAfter,balanceBefore)==amount));
    }

    
}

 
 
 
contract ShopKeeper is SafeMath{
    
    ValueTrader public shop;
    address holderA;  
    address holderB;  
    
    
    modifier onlyHolders(){
        assert(msg.sender == holderA || msg.sender == holderB);
        _;
    }
    
    modifier onlyA(){
        assert(msg.sender == holderA);
        _;
    }
    
    function(){
         
        throw;
    }
    
    function ShopKeeper(address other){
        shop = new ValueTrader();
        holderA = msg.sender;
        holderB = other;
    }
    
    function giveAwayOwnership(address newHolder) onlyHolders {
        if(msg.sender == holderB){
            holderB = newHolder;
        } else {
            holderA = newHolder;
        }
    }
    
    function splitProfits(){
        uint256 unprocessedProfit = shop.balanceOf(this);
        uint256 equalShare = unprocessedProfit/2;
        assert(shop.transfer(holderA,equalShare));
        assert(shop.transfer(holderB,equalShare));
    }
    
     
    
    function toggleDrain() onlyA {
        shop.toggleDrain();
    }
    
    function toggleBurn() onlyA {
        shop.toggleBurn();
    }
    
    function die() onlyA {
        shop.die();
    }
    
    function validateToken(address token_, uint256 bP_, uint256 bL_, uint256 pF_) onlyHolders {
        shop.validateToken(token_,bP_,bL_,pF_);
    }
    
    function configureTokenDividend(address token_, bool hD_, address dA_, bytes dD_) onlyA {
        shop.configureTokenDividend(token_,hD_,dA_,dD_);
    }
    
    function callDividend(address token_) onlyA {
        shop.callDividend(token_);
    }
    
    function invalidateToken(address token_) onlyHolders {
        shop.invalidateToken(token_);
    }
    
    function changeOwner(address owner_) onlyA {
        if(holderB == holderA){ 
             
            shop.changeOwner(owner_); 
        }
        holderA = owner_;
    }
    
    function changeShop(address newShop) onlyA {
        if(holderB == holderA){
             
            shop = ValueTrader(newShop);
        }
    }
    
    function changeFee(uint256 tradeFee) onlyHolders {
        shop.changeFee(tradeFee);
    }
    
    function changeEtherContract(address eC) onlyHolders {
        shop.changeEtherContract(eC);
    }
}

 
contract ProfitContainerAdapter is SafeMath{
    
    address owner;
    address shopLocation;
    address shopKeeperLocation;
    address profitContainerLocation;
    
    modifier owned(){
        assert(msg.sender == owner);
        _;
    }
    
    function changeShop(address newShop) owned {
        shopLocation = newShop;
    }
    
    
    function changeKeeper(address newKeeper) owned {
        shopKeeperLocation = newKeeper;
    }
    
    
    function changeContainer(address newContainer) owned {
        profitContainerLocation = newContainer;
    }
    
    function ProfitContainerAdapter(address sL, address sKL, address pCL){
        owner = msg.sender;
        shopLocation = sL;
        shopKeeperLocation = sKL;
        profitContainerLocation = pCL;
    }
    
    function takeEtherProfits(){
        ShopKeeper(shopKeeperLocation).splitProfits();
        ValueTrader shop = ValueTrader(shopLocation);
        shop.buyEther(shop.balanceOf(this));
        assert(profitContainerLocation.call.value(this.balance)());
    }
    
     
    function takeTokenProfits(address token){
        ShopKeeper(shopKeeperLocation).splitProfits();
        ValueTrader shop = ValueTrader(shopLocation);
        shop.buyToken(token,shop.balanceOf(this));
        assert(Token(token).transfer(profitContainerLocation,Token(token).balanceOf(this)));
    }
    
    function giveAwayHoldership(address holderB) owned {
        ShopKeeper(shopKeeperLocation).giveAwayOwnership(holderB);
    }
    
    function giveAwayOwnership(address newOwner) owned {
        owner = newOwner;
    }
    
}