pragma solidity ^0.4.18;

 
 
 
 
 
 

contract ERC20Interface {
     
    function totalSupply() public constant returns (uint256 _totalSupply);
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract Gifto is ERC20Interface {
    uint public constant decimals = 5;

    string public constant symbol = "Gifto";
    string public constant name = "Gifto";

    bool public _selling = false; 
    uint public _totalSupply = 10 ** 14;  
    uint public _originalBuyPrice = 10 ** 10;  

     
    address public owner;
 
     
    mapping(address => uint256) balances;

     
    mapping(address => bool) approvedInvestorList;
    
     
    mapping(address => uint256) deposit;
    
     
    address[] buyers;
    
     
    uint _icoPercent = 10;
    
     
    uint public _icoSupply = _totalSupply * _icoPercent / 100;
    
     
    uint public _minimumBuy = 10 ** 17;
    
     
    uint public _maximumBuy = 30 * 10 ** 18;
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyNotOwner() {
        require(msg.sender != owner);
        _;
    }

     
    modifier onSale() {
        require(_selling && (_icoSupply > 0) );
        _;
    }

     
    modifier validOriginalBuyPrice() {
        require(_originalBuyPrice > 0);
        _;
    }
    
     
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
     
    modifier validValue(){
         
        require ( (msg.value >= _minimumBuy) &&
                ( (deposit[msg.sender] + msg.value) <= _maximumBuy) );
        _;
    }

     
    function()
        public
        payable
        validValue {
         
        if (deposit[msg.sender] == 0 && msg.value != 0){
             
            buyers.push(msg.sender);
        }
         
        deposit[msg.sender] += msg.value;
    }

     
    function Gifto() 
        public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
     
     
    function totalSupply()
        public 
        constant 
        returns (uint256) {
        return _totalSupply;
    }
    
     
     
    function setIcoPercent(uint256 newIcoPercent)
        public 
        onlyOwner
        returns (bool){
        _icoPercent = newIcoPercent;
        _icoSupply = _totalSupply * _icoPercent / 100;
    }
    
     
     
    function setMinimumBuy(uint256 newMinimumBuy)
        public 
        onlyOwner
        returns (bool){
        _minimumBuy = newMinimumBuy;
    }
    
     
     
    function setMaximumBuy(uint256 newMaximumBuy)
        public 
        onlyOwner
        returns (bool){
        _maximumBuy = newMaximumBuy;
    }
 
     
     
     
    function balanceOf(address _addr) 
        public
        constant 
        returns (uint256) {
        return balances[_addr];
    }
    
     
     
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }
    
     
     
    function filterBuyers(bool isInvestor)
        private
        constant
        returns(address[] filterList){
        address[] memory filterTmp = new address[](buyers.length);
        uint count = 0;
        for (uint i = 0; i < buyers.length; i++){
            if(approvedInvestorList[buyers[i]] == isInvestor){
                filterTmp[count] = buyers[i];
                count++;
            }
        }
        
        filterList = new address[](count);
        for (i = 0; i < count; i++){
            if(filterTmp[i] != 0x0){
                filterList[i] = filterTmp[i];
            }
        }
    }
    
     
    function getInvestorBuyers()
        public
        constant
        returns(address[]){
        return filterBuyers(true);
    }
    
     
    function getNormalBuyers()
        public
        constant
        returns(address[]){
        return filterBuyers(false);
    }
    
     
     
     
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
        return deposit[_addr];
    }
    
     
     
    function getTotalDeposit()
        public
        constant
        returns(uint256 totalDeposit){
        totalDeposit = 0;
        for (uint i = 0; i < buyers.length; i++){
            totalDeposit += deposit[buyers[i]];
        }
    }
    
     
     
     
     
    function deliveryToken(bool isInvestor)
        public
        onlyOwner
        validOriginalBuyPrice {
         
        uint256 sum = 0;
        
        for (uint i = 0; i < buyers.length; i++){
            if(approvedInvestorList[buyers[i]] == isInvestor) {
                
                 
                uint256 requestedUnits = deposit[buyers[i]] / _originalBuyPrice;
                
                 
                if(requestedUnits <= _icoSupply && requestedUnits > 0 ){
                     
                     
                    balances[owner] -= requestedUnits;
                    balances[buyers[i]] += requestedUnits;
                    _icoSupply -= requestedUnits;
                    
                     
                    Transfer(owner, buyers[i], requestedUnits);
                    
                     
                    sum += deposit[buyers[i]];
                    deposit[buyers[i]] = 0;
                }
            }
        }
         
        owner.transfer(sum);
    }
    
     
    function returnETHforNormalBuyers()
        public
        onlyOwner{
        for(uint i = 0; i < buyers.length; i++){
             
            if (!approvedInvestorList[buyers[i]]) {
                 
                uint256 buyerDeposit = deposit[buyers[i]];
                 
                deposit[buyers[i]] = 0;
                 
                buyers[i].transfer(buyerDeposit);
            }
        }
    }
 
     
     
     
     
    function transfer(address _to, uint256 _amount)
        public 
        returns (bool) {
         
         
         
        if ( (balances[msg.sender] >= _amount) &&
             (_amount >= 0) && 
             (balances[_to] + _amount > balances[_to]) ) {  

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            
            return true;

        } else {
            revert();
        }
    }

     
    function turnOnSale() onlyOwner 
        public {
        _selling = true;
    }

     
    function turnOffSale() onlyOwner 
        public {
        _selling = false;
    }

     
    function isSellingNow() 
        public 
        constant
        returns (bool) {
        return _selling;
    }

     
     
    function setBuyPrice(uint newBuyPrice) 
        onlyOwner 
        public {
        _originalBuyPrice = newBuyPrice;
    }

     
     
    function addInvestorList(address[] newInvestorList)
        onlyOwner
        public {
        for (uint i = 0; i < newInvestorList.length; i++){
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }

     
     
    function removeInvestorList(address[] investorList)
        onlyOwner
        public {
        for (uint i = 0; i < investorList.length; i++){
            approvedInvestorList[investorList[i]] = false;
        }
    }

     
     
    function buy() payable
        onlyNotOwner 
        validOriginalBuyPrice
        validInvestor
        onSale 
        public
        returns (uint256 amount) {
         
        uint requestedUnits = msg.value / _originalBuyPrice ;
        
         
        require(requestedUnits <= _icoSupply);

         
        balances[owner] -= requestedUnits;
        balances[msg.sender] += requestedUnits;
        
         
        _icoSupply -= requestedUnits;

         
        Transfer(owner, msg.sender, requestedUnits);

         
        owner.transfer(msg.value);
        
        return requestedUnits;
    }
    
     
     
    function withdraw() onlyOwner 
        public 
        returns (bool) {
        return owner.send(this.balance);
    }
}

 
contract MultiSigWallet {

    event Confirmation(address sender, bytes32 transactionId);
    event Revocation(address sender, bytes32 transactionId);
    event Submission(bytes32 transactionId);
    event Execution(bytes32 transactionId);
    event Deposit(address sender, uint value);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event RequirementChange(uint required);
    event CoinCreation(address coin);

    mapping (bytes32 => Transaction) public transactions;
    mapping (bytes32 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] owners;
    bytes32[] transactionList;
    uint public required;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        uint nonce;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier confirmed(bytes32 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(bytes32 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(bytes32 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address destination) {
        require(destination != 0);
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(   _required <= _ownerCount
                && _required > 0 );
        _;
    }
    
     
     
     
    function MultiSigWallet(address[] _owners, uint _required)
        validRequirement(_owners.length, _required)
        public {
        for (uint i=0; i<_owners.length; i++) {
             
            if (isOwner[_owners[i]] || _owners[i] == 0){
                revert();
            }
             
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

     
    function()
        public
        payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner) {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner) {
         
        require(owners.length > 1);
        
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required) {
        required = _required;
        RequirementChange(_required);
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data, uint nonce)
        private
        notNull(destination)
        returns (bytes32 transactionId) {
         
        transactionId = keccak256(destination, value, data, nonce);
        if (transactions[transactionId].destination == 0) {
            transactions[transactionId] = Transaction({
                destination: destination,
                value: value,
                data: data,
                nonce: nonce,
                executed: false
            });
            transactionList.push(transactionId);
            Submission(transactionId);
        }
    }

     
     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data, uint nonce) external ownerExists(msg.sender) returns (bytes32 transactionId) {
        transactionId = addTransaction(destination, value, data, nonce);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(bytes32 transactionId) public ownerExists(msg.sender) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    
     
     
    function executeTransaction(bytes32 transactionId)   public   notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId]; 
            txn.executed = true;
            if (!txn.destination.call.value(txn.value)(txn.data))
                revert();
            Execution(transactionId);
        }
    }

     
     
    function revokeConfirmation(bytes32 transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
     
    function isConfirmed(bytes32 transactionId)
        public
        constant
        returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
    }

     
     
     
     
    function confirmationCount(bytes32 transactionId)
        external
        constant
        returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
    function filterTransactions(bool isPending)
        private
        constant
        returns (bytes32[] _transactionList) {
        bytes32[] memory _transactionListTemp = new bytes32[](transactionList.length);
        uint count = 0;
        for (uint i=0; i<transactionList.length; i++)
            if (transactions[transactionList[i]].executed != isPending)
            {
                _transactionListTemp[count] = transactionList[i];
                count += 1;
            }
        _transactionList = new bytes32[](count);
        for (i=0; i<count; i++)
            if (_transactionListTemp[i] > 0)
                _transactionList[i] = _transactionListTemp[i];
    }

     
    function getPendingTransactions()
        external
        constant
        returns (bytes32[]) {
        return filterTransactions(true);
    }

     
    function getExecutedTransactions()
        external
        constant
        returns (bytes32[]) {
        return filterTransactions(false);
    }
    
     
    function createCoin()
        external
        onlyWallet
    {
        CoinCreation(new Gifto());
    }
}