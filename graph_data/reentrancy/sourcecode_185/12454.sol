pragma solidity ^0.4.24;

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 
contract RBACWithAdmin is RBAC {
   
  string public constant ROLE_ADMIN = "admin";

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
  function RBACWithAdmin()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

 
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

contract ERC20 {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}


 
contract FacultyPool is RBACWithAdmin {

    using SafeMath for uint;

     
     
    uint8 constant CONTRACT_OPEN = 1;
    uint8 constant CONTRACT_CLOSED = 2;
    uint8 constant CONTRACT_SUBMIT_FUNDS = 3;
     
    uint256 constant public gasLimit = 50000000000;
     
    uint256 constant public minContribution = 100000000000000000;

     
     
     
    address public owner;
     
    uint256 public feePct;
     
    uint8 public contractStage = CONTRACT_OPEN;
     
    uint256 public currentBeneficiaryCap;
     
    uint256 public totalPoolCap;
     
    address public receiverAddress;
     
    mapping (address => Beneficiary) beneficiaries;
     
    uint256 public finalBalance;
     
    uint256[] public ethRefundAmount;
     
    mapping (address => TokenAllocation) tokenAllocationMap;
     
    address public defaultToken;


     
     
     
    modifier isOpenContract() {
        require (contractStage == CONTRACT_OPEN);
        _;
    }

     
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

     
    struct Beneficiary {
        uint256 ethRefund;
        uint256 balance;
        uint256 cap;
        mapping (address => uint256) tokensClaimed;
    }

     
    struct TokenAllocation {
        ERC20 token;
        uint256[] pct;
        uint256 balanceRemaining;
    }

     
     
    event BeneficiaryBalanceChanged(address indexed beneficiary, uint256 totalBalance);
    event ReceiverAddressSet(address indexed receiverAddress);
    event ERC223Received(address indexed token, uint256 value);
    event DepositReceived(address indexed beneficiary, uint256 amount, uint256 gas, uint256 gasprice, uint256 gasLimit);
    event PoolStageChanged(uint8 stage);
    event PoolSubmitted(address indexed receiver, uint256 amount);
    event RefundReceived(address indexed sender, uint256 amount);
    event TokenWithdrawal(address indexed beneficiary, address indexed token, uint256 amount);
    event EthRefunded(address indexed beneficiary, uint256 amount);

     
     

     
    constructor(address[] _admins, uint256 _poolCap, uint256 _beneficiaryCap, address _receiverAddr, uint256 _feePct) public {
        require(_admins.length > 0, "Must have at least one admin apart from msg.sender");
        require(_poolCap >= _beneficiaryCap, "Cannot have the poolCap <= beneficiaryCap");
        require(_feePct >=  0 && _feePct < 10000);
        feePct = _feePct;
        receiverAddress = _receiverAddr;
        totalPoolCap = _poolCap;
        currentBeneficiaryCap = _beneficiaryCap;
         
        owner = msg.sender;
        addRole(msg.sender, ROLE_ADMIN);
        for (uint8 i = 0; i < _admins.length; i++) {
            addRole(_admins[i], ROLE_ADMIN);
        }
    }

     
    function () payable public {
        if (contractStage == CONTRACT_OPEN) {
            emit DepositReceived(msg.sender, msg.value, gasleft(), tx.gasprice, gasLimit);
            _receiveDeposit();
        } else {
            _receiveRefund();
        }
    }

     
    function _receiveDeposit() isOpenContract internal {
        require(tx.gasprice <= gasLimit, "Gas too high");
        require(address(this).balance <= totalPoolCap, "Deposit will put pool over limit. Reverting.");
         
        Beneficiary storage b = beneficiaries[msg.sender];
        uint256 newBalance = b.balance.add(msg.value);
        require(newBalance >= minContribution, "contribution is lower than minContribution");
        if(b.cap > 0){
            require(newBalance <= b.cap, "balance is less than set cap for beneficiary");
        } else if(currentBeneficiaryCap == 0) {
             
            b.cap = totalPoolCap;
        }else {
            require(newBalance <= currentBeneficiaryCap, "balance is more than currentBeneficiaryCap");
             
            b.cap = currentBeneficiaryCap;
        }
        b.balance = newBalance;
        emit BeneficiaryBalanceChanged(msg.sender, newBalance);
    }

     
    function _receiveRefund() internal {
        assert(contractStage >= 2);
        require(hasRole(msg.sender, ROLE_ADMIN) || msg.sender == receiverAddress, "Receiver or Admins only");
        ethRefundAmount.push(msg.value);
        emit RefundReceived(msg.sender, msg.value);
    }

    function getCurrentBeneficiaryCap() public view returns(uint256 cap) {
        return currentBeneficiaryCap;
    }

    function getPoolDetails() public view returns(uint256 total, uint256 currentBalance, uint256 remaining) {
        remaining = totalPoolCap.sub(address(this).balance);
        return (totalPoolCap, address(this).balance, remaining);
    }

     
    function closePool() onlyAdmin isOpenContract public {
        contractStage = CONTRACT_CLOSED;
        emit PoolStageChanged(contractStage);
    }

    function submitPool(uint256 weiAmount) public onlyAdmin noReentrancy { 
        require(contractStage < CONTRACT_SUBMIT_FUNDS, "Cannot resubmit pool.");
        require(receiverAddress != 0x00, "receiver address cannot be empty");
        uint256 contractBalance = address(this).balance;
        if(weiAmount == 0){
            weiAmount = contractBalance;
        }
        require(minContribution <= weiAmount && weiAmount <= contractBalance, "submitted amount too small or larger than the balance");
        finalBalance = contractBalance;
         
        require(receiverAddress.call.value(weiAmount).gas(gasleft().sub(5000))(),"Error submitting pool to receivingAddress");
         
        contractBalance = address(this).balance;
        if(contractBalance > 0) {
            ethRefundAmount.push(contractBalance);
        }
        contractStage = CONTRACT_SUBMIT_FUNDS;
        emit PoolSubmitted(receiverAddress, weiAmount);
    }

    function viewBeneficiaryDetails(address beneficiary) public view returns (uint256 cap, uint256 balance, uint256 remaining, uint256 ethRefund){
        Beneficiary storage b = beneficiaries[beneficiary];
        return (b.cap, b.balance, b.cap.sub(b.balance), b.ethRefund);
    }

    function withdraw(address _tokenAddress) public {
        Beneficiary storage b = beneficiaries[msg.sender];
        require(b.balance > 0, "msg.sender has no balance. Nice Try!");
        if(contractStage == CONTRACT_OPEN){
            uint256 transferAmt = b.balance;
            b.balance = 0;
            msg.sender.transfer(transferAmt);
            emit BeneficiaryBalanceChanged(msg.sender, 0);
        } else {
            _withdraw(msg.sender, _tokenAddress);
        }
    }

     
    function withdrawFor (address _beneficiary, address tokenAddr) public onlyAdmin {
        require (contractStage == CONTRACT_SUBMIT_FUNDS, "Can only be done on Submitted Contract");
        require (beneficiaries[_beneficiary].balance > 0, "Beneficary has no funds to withdraw");
        _withdraw(_beneficiary, tokenAddr);
    }

    function _withdraw (address _beneficiary, address _tokenAddr) internal {
        require(contractStage == CONTRACT_SUBMIT_FUNDS, "Cannot withdraw when contract is not CONTRACT_SUBMIT_FUNDS");
        Beneficiary storage b = beneficiaries[_beneficiary];
        if (_tokenAddr == 0x00) {
            _tokenAddr = defaultToken;
        }
        TokenAllocation storage ta = tokenAllocationMap[_tokenAddr];
        require ( (ethRefundAmount.length > b.ethRefund) || ta.pct.length > b.tokensClaimed[_tokenAddr] );

        if (ethRefundAmount.length > b.ethRefund) {
            uint256 pct = _toPct(b.balance,finalBalance);
            uint256 ethAmount = 0;
            for (uint i= b.ethRefund; i < ethRefundAmount.length; i++) {
                ethAmount = ethAmount.add(_applyPct(ethRefundAmount[i],pct));
            }
            b.ethRefund = ethRefundAmount.length;
            if (ethAmount > 0) {
                _beneficiary.transfer(ethAmount);
                emit EthRefunded(_beneficiary, ethAmount);
            }
        }
        if (ta.pct.length > b.tokensClaimed[_tokenAddr]) {
            uint tokenAmount = 0;
            for (i= b.tokensClaimed[_tokenAddr]; i< ta.pct.length; i++) {
                tokenAmount = tokenAmount.add(_applyPct(b.balance, ta.pct[i]));
            }
            b.tokensClaimed[_tokenAddr] = ta.pct.length;
            if (tokenAmount > 0) {
                require(ta.token.transfer(_beneficiary,tokenAmount));
                ta.balanceRemaining = ta.balanceRemaining.sub(tokenAmount);
                emit TokenWithdrawal(_beneficiary, _tokenAddr, tokenAmount);
            }
        }
    }

    function setReceiver(address addr) public onlyAdmin {
        require (contractStage < CONTRACT_SUBMIT_FUNDS);
        receiverAddress = addr;
        emit ReceiverAddressSet(addr);
    }

     
     
    function enableTokenWithdrawals (address _tokenAddr, bool _useAsDefault) public onlyAdmin noReentrancy {
        require (contractStage == CONTRACT_SUBMIT_FUNDS, "wrong contract stage");
        if (_useAsDefault) {
            defaultToken = _tokenAddr;
        } else {
            require (defaultToken != 0x00, "defaultToken must be set");
        }
        TokenAllocation storage ta  = tokenAllocationMap[_tokenAddr];
        if (ta.pct.length==0){
            ta.token = ERC20(_tokenAddr);
        }
        uint256 amount = ta.token.balanceOf(this).sub(ta.balanceRemaining);
        require (amount > 0);
        if (feePct > 0) {
            uint256 feePctFromBips = _toPct(feePct, 10000);
            uint256 feeAmount = _applyPct(amount, feePctFromBips);
            require (ta.token.transfer(owner, feeAmount));
            emit TokenWithdrawal(owner, _tokenAddr, feeAmount);
        }
        amount = ta.token.balanceOf(this).sub(ta.balanceRemaining);
        ta.balanceRemaining = ta.token.balanceOf(this);
        ta.pct.push(_toPct(amount,finalBalance));
    }

     
    function checkAvailableTokens (address addr, address tokenAddr) view public returns (uint tokenAmount) {
        Beneficiary storage b = beneficiaries[addr];
        TokenAllocation storage ta = tokenAllocationMap[tokenAddr];
        for (uint i = b.tokensClaimed[tokenAddr]; i < ta.pct.length; i++) {
            tokenAmount = tokenAmount.add(_applyPct(b.balance, ta.pct[i]));
        }
        return tokenAmount;
    }

     
    function tokenFallback (address from, uint value, bytes data) public {
        emit ERC223Received (from, value);
    }

     
    function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
        return numerator.mul(10 ** 20) / denominator;
    }

     
    function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
        return numerator.mul(pct) / (10 ** 20);
    }


}