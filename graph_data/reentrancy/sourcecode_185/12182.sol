pragma solidity ^0.4.23;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender; 
    }

     
    function setOwner(address _owner) public onlyOwner returns (bool) {
        require(_owner != address(0));
        owner = _owner;
        return true;
    } 
}

interface TokenHandler {
    function handleTokens(Token _token) public returns (bool);
}

contract HasWorkers is Ownable {
    mapping(address => uint256) private workerToIndex;    
    address[] private workers;

    event AddedWorker(address _worker);
    event RemovedWorker(address _worker);

    constructor() public {
        workers.length++;
    }

    modifier onlyWorker() {
        require(isWorker(msg.sender));
        _;
    }

    modifier workerOrOwner() {
        require(isWorker(msg.sender) || msg.sender == owner);
        _;
    }

    function isWorker(address _worker) public view returns (bool) {
        return workerToIndex[_worker] != 0;
    }

    function allWorkers() public view returns (address[] memory result) {
        result = new address[](workers.length - 1);
        for (uint256 i = 1; i < workers.length; i++) {
            result[i - 1] = workers[i];
        }
    }

    function addWorker(address _worker) public onlyOwner returns (bool) {
        require(!isWorker(_worker));
        uint256 index = workers.push(_worker) - 1;
        workerToIndex[_worker] = index;
        emit AddedWorker(_worker);
        return true;
    }

    function removeWorker(address _worker) public onlyOwner returns (bool) {
        require(isWorker(_worker));
        uint256 index = workerToIndex[_worker];
        address lastWorker = workers[workers.length - 1];
        workerToIndex[lastWorker] = index;
        workers[index] = lastWorker;
        workers.length--;
        delete workerToIndex[_worker];
        emit RemovedWorker(_worker);
        return true;
    }
}

contract ControllerStorage {
    address public walletsDelegate;
    address public controllerDelegate;
    address public forward;
    uint256 public createdWallets;
    mapping(bytes32 => bytes32) public gStorage;
}

contract WalletStorage {
    address public owner;
}

contract DelegateProxy {
   
  function delegatedFwd(address _dst, bytes _calldata) internal {
    assembly {
      let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

       
       
      switch result case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

contract DelegateProvider {
    function getDelegate() public view returns (address delegate);
}

contract ControllerProxy is ControllerStorage, Ownable, HasWorkers, DelegateProvider, DelegateProxy {
    function getDelegate() public view returns (address delegate) {
        delegate = walletsDelegate;
    }

    function setWalletsDelegate(address _delegate) public onlyOwner returns (bool) {
        walletsDelegate = _delegate;
        return true;
    }

    function setControllerDelegate(address _delegate) public onlyOwner returns (bool) {
        controllerDelegate = _delegate;
        return true;
    }

    function() public payable {
        if (gasleft() > 2400) {
            delegatedFwd(controllerDelegate, msg.data);
        }
    }
}

contract Token {
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function approve(address _spender, uint256 _value) returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
}

contract WalletProxy is WalletStorage, DelegateProxy {
    event ReceivedETH(address from, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    function() public payable {
        if (msg.value > 0) {
            emit ReceivedETH(msg.sender, msg.value);
        }
        if (gasleft() > 2400) {
            delegatedFwd(DelegateProvider(owner).getDelegate(), msg.data);
        }
    }
}

contract Wallet is WalletStorage {
    function transferERC20Token(Token token, address to, uint256 amount) public returns (bool) {
        require(msg.sender == owner);
        return token.transfer(to, amount);
    }
    
    function transferEther(address to, uint256 amount) public returns (bool) {
        require(msg.sender == owner);
        return to.call.value(amount)();
    }

    function() public payable {}
}

contract Controller is ControllerStorage, Ownable, HasWorkers {
    event CreatedUserWallet(address _wallet);

     
    event WithdrawEth(address _wallet, address _to, uint256 _amount);
    event WithdrawToken(address _token, address _wallet, address _to, uint256 _amount);
    event ChangedForward(address _old, address _new, address _operator);

    constructor() public {
        setForward(msg.sender);
    }

     
    function executeTransaction(address destination, uint256 value, bytes memory _bytes) public onlyOwner returns (bool) {
        return destination.call.value(value)(_bytes);
    }

     
    function setForward(address _forward) public onlyOwner returns (bool) {
        emit ChangedForward(forward, _forward, msg.sender);
        forward = _forward;
        return true;
    }

     
    function createWallets(uint256 number) public onlyWorker returns (bool) {
        for (uint256 i = 0; i < number; i++) {
            emit CreatedUserWallet(new WalletProxy());
        }

        createdWallets += number;
        return true;
    }

     
    function withdrawEth(Wallet wallet) public onlyWorker returns (bool result) {
        uint256 balance = address(wallet).balance;
        result = wallet.transferEther(forward, balance);
        
        if (result) {
            emit WithdrawEth(wallet, forward, balance);
        }
    }

     
    function withdrawEthBatch(Wallet[] wallets) public onlyWorker returns (bool) {
        uint256 size = wallets.length;
        uint256 balance;
        
        Wallet wallet;

        for (uint256 i = 0; i < size; i++) {
            wallet = wallets[i];
            balance = wallet.balance;
            
            if (wallet.transferEther(this, balance)) {
                emit WithdrawEth(wallet, forward, balance);
            }  
        }

        forward.call.value(address(this).balance)();

        return true;
    }

     
    function withdrawERC20(Token token, Wallet wallet) public onlyWorker returns (bool result) {
        uint256 balance = token.balanceOf(wallet);
        result = wallet.transferERC20Token(token, forward, balance);
        
        if (result) {
            emit WithdrawToken(token, wallet, forward, balance);
        }

        TokenHandler(forward).handleTokens(token);
    }

     
    function withdrawERC20Batch(Token token, Wallet[] wallets) public onlyWorker returns (bool) {
        uint256 size = wallets.length;
        uint256 balance;
        Wallet wallet;

        for (uint256 i = 0; i < size; i++) {
            wallet = wallets[i];
            balance = token.balanceOf(wallet);
            
            if (wallet.transferERC20Token(token, forward, balance)) {
                emit WithdrawToken(token, wallet, forward, balance);
            }
        }

        TokenHandler(forward).handleTokens(token);

        return true;
    }

    function() public payable {}
}