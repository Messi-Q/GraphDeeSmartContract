pragma solidity ^0.4.18;

contract ETHPriceWatcher {
  address public ethPriceProvider;

  modifier onlyEthPriceProvider() {
    require(msg.sender == ethPriceProvider);
    _;
  }

  function receiveEthPrice(uint ethUsdPrice) external;

  function setEthPriceProvider(address provider) external;
}


contract OraclizeI {
  address public cbAddress;
  function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
  function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
  function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
  function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
  function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
  function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
  function getPrice(string _datasource) public returns (uint _dsprice);
  function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
  function setProofType(byte _proofType) external;
  function setCustomGasPrice(uint _gasPrice) external;
  function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}
contract OraclizeAddrResolverI {
  function getAddress() public returns (address _addr);
}
contract usingOraclize {
  uint constant day = 60*60*24;
  uint constant week = 60*60*24*7;
  uint constant month = 60*60*24*30;
  byte constant proofType_NONE = 0x00;
  byte constant proofType_TLSNotary = 0x10;
  byte constant proofType_Android = 0x20;
  byte constant proofType_Ledger = 0x30;
  byte constant proofType_Native = 0xF0;
  byte constant proofStorage_IPFS = 0x01;
  uint8 constant networkID_auto = 0;
  uint8 constant networkID_mainnet = 1;
  uint8 constant networkID_testnet = 2;
  uint8 constant networkID_morden = 2;
  uint8 constant networkID_consensys = 161;

  OraclizeAddrResolverI OAR;

  OraclizeI oraclize;
  modifier oraclizeAPI {
    if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
      oraclize_setNetwork(networkID_auto);

    if(address(oraclize) != OAR.getAddress())
      oraclize = OraclizeI(OAR.getAddress());

    _;
  }
  modifier coupon(string code){
    oraclize = OraclizeI(OAR.getAddress());
    _;
  }

  function oraclize_setNetwork(uint8 networkID) internal returns(bool){
    return oraclize_setNetwork();
    networkID;  
  }
  function oraclize_setNetwork() internal returns(bool){
    if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
      OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
      oraclize_setNetworkName("eth_mainnet");
      return true;
    }
    if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
      OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
      oraclize_setNetworkName("eth_ropsten3");
      return true;
    }
    if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
      OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
      oraclize_setNetworkName("eth_kovan");
      return true;
    }
    if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
      OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
      oraclize_setNetworkName("eth_rinkeby");
      return true;
    }
    if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
      OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
      return true;
    }
    if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
      OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
      return true;
    }
    if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
      OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
      return true;
    }
    return false;
  }

  function __callback(bytes32 myid, string result) public {
    __callback(myid, result);
  }

  function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
    return oraclize.getPrice(datasource);
  }

  function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
    return oraclize.getPrice(datasource, gaslimit);
  }

  function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
    uint price = oraclize.getPrice(datasource);
    if (price > 1 ether + tx.gasprice*200000) return 0;  
    return oraclize.query.value(price)(timestamp, datasource, arg);
  }
  function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
    uint price = oraclize.getPrice(datasource, gaslimit);
    if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
    return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
  }

  function oraclize_cbAddress() oraclizeAPI internal returns (address){
    return oraclize.cbAddress();
  }
  function oraclize_setProof(byte proofP) oraclizeAPI internal {
    return oraclize.setProofType(proofP);
  }
  function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
    return oraclize.setCustomGasPrice(gasPrice);
  }

  function getCodeSize(address _addr) constant internal returns(uint _size) {
    assembly {
      _size := extcodesize(_addr)
    }
  }

   
  function parseInt(string _a) internal pure returns (uint) {
    return parseInt(_a, 0);
  }

   
  function parseInt(string _a, uint _b) internal pure returns (uint) {
    bytes memory bresult = bytes(_a);
    uint mint = 0;
    bool decimals = false;
    for (uint i=0; i<bresult.length; i++){
      if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
        if (decimals){
          if (_b == 0) break;
          else _b--;
        }
        mint *= 10;
        mint += uint(bresult[i]) - 48;
      } else if (bresult[i] == 46) decimals = true;
    }
    if (_b > 0) mint *= 10**_b;
    return mint;
  }

  string oraclize_network_name;
  function oraclize_setNetworkName(string _network_name) internal {
    oraclize_network_name = _network_name;
  }

  function oraclize_getNetworkName() internal view returns (string) {
    return oraclize_network_name;
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

contract BuildingStatus is Ownable {
   
  address public observer;

   
  address public crowdsale;

  enum statusEnum {
      crowdsale,
      refund,
      preparation_works,
      building_permit,
      design_technical_documentation,
      utilities_outsite,
      construction_residential,
      frame20,
      frame40,
      frame60,
      frame80,
      frame100,
      stage1,
      stage2,
      stage3,
      stage4,
      stage5,
      facades20,
      facades40,
      facades60,
      facades80,
      facades100,
      engineering,
      finishing,
      construction_parking,
      civil_works,
      engineering_further,
      commisioning_project,
      completed
  }

  modifier notCompleted() {
      require(status != statusEnum.completed);
      _;
  }

  modifier onlyObserver() {
    require(msg.sender == observer || msg.sender == owner || msg.sender == address(this));
    _;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale || msg.sender == owner || msg.sender == address(this));
    _;
  }

  statusEnum public status;

  event StatusChanged(statusEnum newStatus);

  function setStatus(statusEnum newStatus) onlyCrowdsale  public {
      status = newStatus;
      StatusChanged(newStatus);
  }

  function changeStage(uint8 stage) public onlyObserver {
      if (stage==1) status = statusEnum.stage1;
      if (stage==2) status = statusEnum.stage2;
      if (stage==3) status = statusEnum.stage3;
      if (stage==4) status = statusEnum.stage4;
      if (stage==5) status = statusEnum.stage5;
  }
 
}

 
contract PermissionManager is Ownable {
    mapping (address => bool) permittedAddresses;

    function addAddress(address newAddress) public onlyOwner {
        permittedAddresses[newAddress] = true;
    }

    function removeAddress(address remAddress) public onlyOwner {
        permittedAddresses[remAddress] = false;
    }

    function isPermitted(address pAddress) public view returns(bool) {
        if (permittedAddresses[pAddress]) {
            return true;
        }
        return false;
    }
}

contract Registry is Ownable {

  struct ContributorData {
    bool isActive;
    uint contributionETH;
    uint contributionUSD;
    uint tokensIssued;
    uint quoteUSD;
    uint contributionRNTB;
  }
  mapping(address => ContributorData) public contributorList;
  mapping(uint => address) private contributorIndexes;

  uint private nextContributorIndex;

   
  PermissionManager public permissionManager;

  bool public completed;

  modifier onlyPermitted() {
    require(permissionManager.isPermitted(msg.sender));
    _;
  }

  event ContributionAdded(address _contributor, uint overallEth, uint overallUSD, uint overallToken, uint quote);
  event ContributionEdited(address _contributor, uint overallEth, uint overallUSD,  uint overallToken, uint quote);
  function Registry(address pManager) public {
    permissionManager = PermissionManager(pManager); 
    completed = false;
  }

  function setPermissionManager(address _permadr) public onlyOwner {
    require(_permadr != 0x0);
    permissionManager = PermissionManager(_permadr);
  }

  function isActiveContributor(address contributor) public view returns(bool) {
    return contributorList[contributor].isActive;
  }

  function removeContribution(address contributor) public onlyPermitted {
    contributorList[contributor].isActive = false;
  }

  function setCompleted(bool compl) public onlyPermitted {
    completed = compl;
  }

  function addContribution(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote ) public onlyPermitted {
    
    if (contributorList[_contributor].isActive == false) {
        contributorList[_contributor].isActive = true;
        contributorList[_contributor].contributionETH = _amount;
        contributorList[_contributor].contributionUSD = _amusd;
        contributorList[_contributor].tokensIssued = _tokens;
        contributorList[_contributor].quoteUSD = _quote;

        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex++;
    } else {
      contributorList[_contributor].contributionETH += _amount;
      contributorList[_contributor].contributionUSD += _amusd;
      contributorList[_contributor].tokensIssued += _tokens;
      contributorList[_contributor].quoteUSD = _quote;
    }
    ContributionAdded(_contributor, contributorList[_contributor].contributionETH, contributorList[_contributor].contributionUSD, contributorList[_contributor].tokensIssued, contributorList[_contributor].quoteUSD);
  }

  function editContribution(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote) public onlyPermitted {
    if (contributorList[_contributor].isActive == true) {
        contributorList[_contributor].contributionETH = _amount;
        contributorList[_contributor].contributionUSD = _amusd;
        contributorList[_contributor].tokensIssued = _tokens;
        contributorList[_contributor].quoteUSD = _quote;
    }
     ContributionEdited(_contributor, contributorList[_contributor].contributionETH, contributorList[_contributor].contributionUSD, contributorList[_contributor].tokensIssued, contributorList[_contributor].quoteUSD);
  }

  function addContributor(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote) public onlyPermitted {
    contributorList[_contributor].isActive = true;
    contributorList[_contributor].contributionETH = _amount;
    contributorList[_contributor].contributionUSD = _amusd;
    contributorList[_contributor].tokensIssued = _tokens;
    contributorList[_contributor].quoteUSD = _quote;
    contributorIndexes[nextContributorIndex] = _contributor;
    nextContributorIndex++;
    ContributionAdded(_contributor, contributorList[_contributor].contributionETH, contributorList[_contributor].contributionUSD, contributorList[_contributor].tokensIssued, contributorList[_contributor].quoteUSD);
 
  }

  function getContributionETH(address _contributor) public view returns (uint) {
      return contributorList[_contributor].contributionETH;
  }

  function getContributionUSD(address _contributor) public view returns (uint) {
      return contributorList[_contributor].contributionUSD;
  }

  function getContributionRNTB(address _contributor) public view returns (uint) {
      return contributorList[_contributor].contributionRNTB;
  }

  function getContributionTokens(address _contributor) public view returns (uint) {
      return contributorList[_contributor].tokensIssued;
  }

  function addRNTBContribution(address _contributor, uint _amount) public onlyPermitted {
    if (contributorList[_contributor].isActive == false) {
        contributorList[_contributor].isActive = true;
        contributorList[_contributor].contributionRNTB = _amount;
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex++;
    } else {
      contributorList[_contributor].contributionETH += _amount;
    }
  }

  function getContributorByIndex(uint index) public view  returns (address) {
      return contributorIndexes[index];
  }

  function getContributorAmount() public view returns(uint) {
      return nextContributorIndex;
  }

}

 
contract OraclizeC is Ownable, usingOraclize {
  uint public updateInterval = 300;  
  uint public gasLimit = 200000;  
  mapping (bytes32 => bool) validIds;
  string public url;

  enum State { New, Stopped, Active }

  State public state = State.New;

  event LogOraclizeQuery(string description, uint balance, uint blockTimestamp);
  event LogOraclizeAddrResolverI(address oar);

  modifier inActiveState() {
    require(state == State.Active);
    _;
  }

  modifier inStoppedState() {
    require(state == State.Stopped);
    _;
  }

  modifier inNewState() {
    require(state == State.New);
    _;
  }

  function setUpdateInterval(uint newInterval) external onlyOwner {
    require(newInterval > 0);
    updateInterval = newInterval;
  }

  function setUrl(string newUrl) external onlyOwner {
    require(bytes(newUrl).length > 0);
    url = newUrl;
  }

  function setGasLimit(uint _gasLimit) external onlyOwner {
    require(_gasLimit > 50000);
    gasLimit = _gasLimit;
  }

  function setGasPrice(uint gasPrice) external onlyOwner {
    require(gasPrice >= 1000000000);  
    oraclize_setCustomGasPrice(gasPrice);
  }

   
  function setOraclizeAddrResolverI(address __oar) public onlyOwner {
    require(__oar != 0x0);
    OAR = OraclizeAddrResolverI(__oar);
    LogOraclizeAddrResolverI(__oar);
  }

   
  function withdraw(address receiver) external onlyOwner inStoppedState {
    require(receiver != 0x0);
    receiver.transfer(this.balance);
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
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

 
contract ETHPriceProvider is OraclizeC {
  using SafeMath for uint;

  uint public currentPrice;

  ETHPriceWatcher public watcher;

  event LogPriceUpdated(string getPrice, uint setPrice, uint blockTimestamp);
  event LogStartUpdate(uint startingPrice, uint updateInterval, uint blockTimestamp);

  function notifyWatcher() internal;

  function ETHPriceProvider(string _url) payable public {
    url = _url;

     
     
  }

   
  function startUpdate(uint startingPrice) payable onlyOwner inNewState public {
    state = State.Active;

    currentPrice = startingPrice;
    update(updateInterval);
    notifyWatcher();
    LogStartUpdate(startingPrice, updateInterval, block.timestamp);
  }

  function stopUpdate() external onlyOwner inActiveState {
    state = State.Stopped;
  }

  function setWatcher(address newWatcher) external onlyOwner {
    require(newWatcher != 0x0);
    watcher = ETHPriceWatcher(newWatcher);
  }

  function __callback(bytes32 myid, string result) public {
    require(msg.sender == oraclize_cbAddress() && validIds[myid]);
    delete validIds[myid];

    uint newPrice = parseInt(result, 2);

    if (state == State.Active) {
      update(updateInterval);
    }

    require(newPrice > 0);

    currentPrice = newPrice;

    notifyWatcher();
    LogPriceUpdated(result,newPrice,block.timestamp);
  }

  function update(uint delay) private {
    if (oraclize_getPrice("URL") > this.balance) {
       
      state = State.Stopped;
      LogOraclizeQuery("Oraclize query was NOT sent", this.balance,block.timestamp);
    } else {
      bytes32 queryId = oraclize_query(delay, "URL", url, gasLimit);
      validIds[queryId] = true;
    }
  }

  function getQuote() public constant returns (uint) {
    return currentPrice;
  }

}

contract ConvertQuote is ETHPriceProvider {
   
  function ConvertQuote(uint _currentPrice) ETHPriceProvider("BIa/Nnj1+ipZBrrLIgpTsI6ukQTlTJMd1c0iC7zvxx+nZzq9ODgBSmCLo3Zc0sYZwD8mlruAi5DblQvt2cGsfVeCyqaxu+1lWD325kgN6o0LxrOUW9OQWn2COB3TzcRL51Q+ZLBsT955S1OJbOqsfQ4gg/l2awe2EFVuO3WTprvwKhAa8tjl2iPYU/AJ83TVP9Kpz+ugTJumlz2Y6SPBGMNcvBoRq3MlnrR2h/XdqPbh3S2bxjbSTLwyZzu2DAgVtybPO1oJETY=") payable public {
    currentPrice = _currentPrice;
  }

  function notifyWatcher() internal {
    if(address(watcher) != 0x0) {
      watcher.receiveEthPrice(currentPrice);
    }
  }
}

 
 
contract ERC223ReceivingContract {

  struct TKN {
    address sender;
    uint value;
    bytes data;
    bytes4 sig;
  }

   
  function tokenFallback(address _from, uint _value, bytes _data) public pure {
    TKN memory tkn;
    tkn.sender = _from;
    tkn.value = _value;
    tkn.data = _data;
    if(_data.length > 0) {
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
    }

     
  }

}

contract ERC223Interface {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function allowedAddressesOf(address who) public view returns (bool);
  function getTotalSupply() public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
  event TransferContract(address indexed from, address indexed to, uint value, bytes data);
}

 

contract UnityToken is ERC223Interface {
  using SafeMath for uint;

  string public constant name = "Unity Token";
  string public constant symbol = "UNT";
  uint8 public constant decimals = 18;


   
  uint public constant INITIAL_SUPPLY = 100000 * (10 ** uint(decimals));

  mapping(address => uint) balances;  
  mapping(address => bool) allowedAddresses;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function addAllowed(address newAddress) public onlyOwner {
    allowedAddresses[newAddress] = true;
  }

  function removeAllowed(address remAddress) public onlyOwner {
    allowedAddresses[remAddress] = false;
  }


  address public owner;

   
  function UnityToken() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[owner] = INITIAL_SUPPLY;
  }

  function getTotalSupply() public view returns (uint) {
    return totalSupply;
  }

   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if (isContract(_to)) {
      require(allowedAddresses[_to]);
      if (balanceOf(msg.sender) < _value) revert();

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      TransferContract(msg.sender, _to, _value, _data);
      return true;
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }


   
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

    if (isContract(_to)) {
      return transferToContract(_to, _value, _data);
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

   
   
  function transfer(address _to, uint _value) public returns (bool success) {
     
     
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(_to, _value, empty);
    } else {
      return transferToAddress(_to, _value, empty);
    }
  }

   
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      length := extcodesize(_addr)
    }
    return (length > 0);
  }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value)  revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(allowedAddresses[_to]);
    if (balanceOf(msg.sender) < _value)
      revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    TransferContract(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function allowedAddressesOf(address _owner) public view returns (bool allowed) {
    return allowedAddresses[_owner];
  }
}

 
contract Hold is Ownable {

    uint8 stages = 5;
    uint8 public percentage;
    uint8 public currentStage;
    uint public initialBalance;
    uint public withdrawed;
    
    address public multisig;
    Registry registry;

    PermissionManager public permissionManager;
    uint nextContributorToTransferEth;
    address public observer;
    uint dateDeployed;
    mapping(address => bool) private hasWithdrawedEth;

    event InitialBalanceChanged(uint balance);
    event EthReleased(uint ethreleased);
    event EthRefunded(address contributor, uint ethrefunded);
    event StageChanged(uint8 newStage);
    event EthReturnedToOwner(address owner, uint balance);

    modifier onlyPermitted() {
        require(permissionManager.isPermitted(msg.sender) || msg.sender == owner);
        _;
    }

    modifier onlyObserver() {
        require(msg.sender == observer || msg.sender == owner);
        _;
    }

    function Hold(address _multisig, uint cap, address pm, address registryAddress, address observerAddr) public {
        percentage = 100 / stages;
        currentStage = 0;
        multisig = _multisig;
        initialBalance = cap;
        dateDeployed = now;
        permissionManager = PermissionManager(pm);
        registry = Registry(registryAddress);
        observer = observerAddr;
    }

    function setPermissionManager(address _permadr) public onlyOwner {
        require(_permadr != 0x0);
        permissionManager = PermissionManager(_permadr);
    }

    function setObserver(address observerAddr) public onlyOwner {
        require(observerAddr != 0x0);
        observer = observerAddr;
    }

    function setInitialBalance(uint inBal) public {
        initialBalance = inBal;
        InitialBalanceChanged(inBal);
    }

    function releaseAllETH() onlyPermitted public {
        uint balReleased = getBalanceReleased();
        require(balReleased > 0);
        require(this.balance >= balReleased);
        multisig.transfer(balReleased);
        withdrawed += balReleased;
        EthReleased(balReleased);
    }

    function releaseETH(uint n) onlyPermitted public {
        require(this.balance >= n);
        require(getBalanceReleased() >= n);
        multisig.transfer(n);
        withdrawed += n;
        EthReleased(n);
    } 

    function getBalance() public view returns (uint) {
        return this.balance;
    }

    function changeStageAndReleaseETH() public onlyObserver {
        uint8 newStage = currentStage + 1;
        require(newStage <= stages);
        currentStage = newStage;
        StageChanged(newStage);
        releaseAllETH();
    }

    function changeStage() public onlyObserver {
        uint8 newStage = currentStage + 1;
        require(newStage <= stages);
        currentStage = newStage;
        StageChanged(newStage);
    }

    function getBalanceReleased() public view returns (uint) {
        return initialBalance * percentage * currentStage / 100 - withdrawed ;
    }

    function returnETHByOwner() public onlyOwner {
        require(now > dateDeployed + 183 days);
        uint balance = getBalance();
        owner.transfer(getBalance());
        EthReturnedToOwner(owner, balance);
    }

    function refund(uint _numberOfReturns) public onlyOwner {
        require(_numberOfReturns > 0);
        address currentParticipantAddress;

        for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
            currentParticipantAddress = registry.getContributorByIndex(nextContributorToTransferEth);
            if (currentParticipantAddress == 0x0) 
                return;

            if (!hasWithdrawedEth[currentParticipantAddress]) {
                uint EthAmount = registry.getContributionETH(currentParticipantAddress);
                EthAmount -=  EthAmount * (percentage / 100 * currentStage);

                currentParticipantAddress.transfer(EthAmount);
                EthRefunded(currentParticipantAddress, EthAmount);
                hasWithdrawedEth[currentParticipantAddress] = true;
            }
            nextContributorToTransferEth += 1;
        }
        
    }  

    function() public payable {

    }

  function getWithdrawed(address contrib) public onlyPermitted view returns (bool) {
    return hasWithdrawedEth[contrib];
  }
}

contract Crowdsale is Pausable, ETHPriceWatcher, ERC223ReceivingContract {
  using SafeMath for uint256;

  UnityToken public token;

  Hold hold;
  ConvertQuote convert;
  Registry registry;

  enum SaleState  {NEW, SALE, ENDED, REFUND}

   
  uint public softCap;
   
  uint public hardCap;
   
  uint public hardCapToken;

   
  uint public startDate;
  uint public endDate;

  uint public ethUsdPrice;  
  uint public tokenUSDRate;  

   
  uint private ethRaised;
   
  uint private usdRaised;

   
  uint private totalTokens;
   
  uint public withdrawedTokens;
   
  uint public minimalContribution;

  bool releasedTokens;
  BuildingStatus public statusI;

  PermissionManager public permissionManager;

   
  uint private minimumTokensToStart;
  SaleState public state;

  uint private nextContributorToClaim;
  uint private nextContributorToTransferTokens;

  mapping(address => bool) private hasWithdrawedTokens;  
  mapping(address => bool) private hasRefunded;  

   
  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event SoftCapReached(uint blockNumber);
  event HardCapReached(uint blockNumber);
  event ContributionAdded(address contrib, uint amount, uint amusd, uint tokens, uint ethusdrate);
  event ContributionAddedManual(address contrib, uint amount, uint amusd, uint tokens, uint ethusdrate);
  event ContributionEdit(address contrib, uint amount, uint amusd, uint tokens, uint ethusdrate);
  event ContributionRemoved(address contrib, uint amount, uint amusd, uint tokens);
  event TokensTransfered(address contributor, uint amount);
  event Refunded(address ref, uint amount);
  event ErrorSendingETH(address to, uint amount);
  event WithdrawedEthToHold(uint amount);
  event ManualChangeStartDate(uint beforeDate, uint afterDate);
  event ManualChangeEndDate(uint beforeDate, uint afterDate);
  event TokensTransferedToHold(address hold, uint amount);
  event TokensTransferedToOwner(address hold, uint amount);
  event ChangeMinAmount(uint oldMinAmount, uint minAmount);
  event ChangePreSale(address preSale);
  event ChangeTokenUSDRate(uint oldTokenUSDRate, uint tokenUSDRate);
  event ChangeHardCapToken(uint oldHardCapToken, uint newHardCapToken);
  event SoftCapChanged();
  event HardCapChanged();

  modifier onlyPermitted() {
    require(permissionManager.isPermitted(msg.sender) || msg.sender == owner);
    _;
  }

  function Crowdsale(
    address tokenAddress,
    address registryAddress,
    address _permissionManager,
    uint start,
    uint end,
    uint _softCap,
    uint _hardCap,
    address holdCont,
    uint _ethUsdPrice) public
  {
    token = UnityToken(tokenAddress);
    permissionManager = PermissionManager(_permissionManager);
    state = SaleState.NEW;

    startDate = start;
    endDate = end;
    minimalContribution = 0.3 * 1 ether;
    tokenUSDRate = 44500;  
    releasedTokens = false;

    softCap = _softCap * 1 ether;
    hardCap = _hardCap * 1 ether;
    hardCapToken = 100000 * 1 ether;

    ethUsdPrice = _ethUsdPrice;

    hold = Hold(holdCont);
    registry = Registry(registryAddress);
  }


  function setPermissionManager(address _permadr) public onlyOwner {
    require(_permadr != 0x0);
    permissionManager = PermissionManager(_permadr);
  }


  function setRegistry(address _regadr) public onlyOwner {
    require(_regadr != 0x0);
    registry = Registry(_regadr);
  }

  function setTokenUSDRate(uint _tokenUSDRate) public onlyOwner {
    require(_tokenUSDRate > 0);
    uint oldTokenUSDRate = tokenUSDRate;
    tokenUSDRate = _tokenUSDRate;
    ChangeTokenUSDRate(oldTokenUSDRate, _tokenUSDRate);
  }

  function getTokenUSDRate() public view returns (uint) {
    return tokenUSDRate;
  }

  function receiveEthPrice(uint _ethUsdPrice) external onlyEthPriceProvider {
    require(_ethUsdPrice > 0);
    ethUsdPrice = _ethUsdPrice;
  }

  function setEthPriceProvider(address provider) external onlyOwner {
    require(provider != 0x0);
    ethPriceProvider = provider;
  }

   
  function setHold(address holdCont) public onlyOwner {
    require(holdCont != 0x0);
    hold = Hold(holdCont);
  }

  function setToken(address tokCont) public onlyOwner {
    require(tokCont != 0x0);
    token = UnityToken(tokCont);
  }

  function setStatusI(address statI) public onlyOwner {
    require(statI != 0x0);
    statusI = BuildingStatus(statI);
  }

  function setStartDate(uint date) public onlyOwner {
    uint oldStartDate = startDate;
    startDate = date;
    ManualChangeStartDate(oldStartDate, date);
  }

  function setEndDate(uint date) public onlyOwner {
    uint oldEndDate = endDate;
    endDate = date;
    ManualChangeEndDate(oldEndDate, date);
  }

  function setSoftCap(uint _softCap) public onlyOwner {
    softCap = _softCap * 1 ether;
    SoftCapChanged();
  }

  function setHardCap(uint _hardCap) public onlyOwner {
    hardCap = _hardCap * 1 ether;
    HardCapChanged();
  }

  function setMinimalContribution(uint minimumAmount) public onlyOwner {
    uint oldMinAmount = minimalContribution;
    minimalContribution = minimumAmount;
    ChangeMinAmount(oldMinAmount, minimalContribution);
  }

  function setHardCapToken(uint _hardCapToken) public onlyOwner {
    require(_hardCapToken > 1 ether);  
    uint oldHardCapToken = _hardCapToken;
    hardCapToken = _hardCapToken;
    ChangeHardCapToken(oldHardCapToken, hardCapToken);
  }

   
  function() whenNotPaused public payable {
    require(state == SaleState.SALE);
    require(now >= startDate);
    require(msg.value >= minimalContribution);

    bool ckeck = checkCrowdsaleState(msg.value);

    if(ckeck) {
      processTransaction(msg.sender, msg.value);
    } else {
      msg.sender.transfer(msg.value);
    }
  }

   
  function checkCrowdsaleState(uint _amount) internal returns (bool) {
    uint usd = _amount.mul(ethUsdPrice);
    if (usdRaised.add(usd) >= hardCap) {
      state = SaleState.ENDED;
      statusI.setStatus(BuildingStatus.statusEnum.preparation_works);
      HardCapReached(block.number);
      CrowdsaleEnded(block.number);
      return true;
    }

    if (now > endDate) {
      if (usdRaised.add(usd) >= softCap) {
        state = SaleState.ENDED;
        statusI.setStatus(BuildingStatus.statusEnum.preparation_works);
        CrowdsaleEnded(block.number);
        return false;
      } else {
        state = SaleState.REFUND;
        statusI.setStatus(BuildingStatus.statusEnum.refund);
        CrowdsaleEnded(block.number);
        return false;
      }
    }
    return true;
  }

   
  function processTransaction(address _contributor, uint _amount) internal {

    require(msg.value >= minimalContribution);

    uint maxContribution = calculateMaxContributionUsd();
    uint contributionAmountUsd = _amount.mul(ethUsdPrice);
    uint contributionAmountETH = _amount;

    uint returnAmountETH = 0;

    if (maxContribution < contributionAmountUsd) {
      contributionAmountUsd = maxContribution;
      uint returnAmountUsd = _amount.mul(ethUsdPrice) - maxContribution;
      returnAmountETH = contributionAmountETH - returnAmountUsd.div(ethUsdPrice);
      contributionAmountETH = contributionAmountETH.sub(returnAmountETH);
    }

    if (usdRaised + contributionAmountUsd >= softCap && softCap > usdRaised) {
      SoftCapReached(block.number);
    }

     
     
    uint tokens = contributionAmountUsd.div(tokenUSDRate);

    if(totalTokens + tokens > hardCapToken) {
      _contributor.transfer(_amount);
    } else {
      if (tokens > 0) {
        registry.addContribution(_contributor, contributionAmountETH, contributionAmountUsd, tokens, ethUsdPrice);
        ethRaised += contributionAmountETH;
        totalTokens += tokens;
        usdRaised += contributionAmountUsd;
        ContributionAdded(_contributor, contributionAmountETH, contributionAmountUsd, tokens, ethUsdPrice);
      }
    }

    if (returnAmountETH != 0) {
      _contributor.transfer(returnAmountETH);
    }
  }

   
  function refundTransaction(bool _stateChanged) internal {
    if (_stateChanged) {
      msg.sender.transfer(msg.value);
    } else{
      revert();
    }
  }

  function getTokensIssued() public view returns (uint) {
    return totalTokens;
  }

  function getTotalUSDInTokens() public view returns (uint) {
    return totalTokens.mul(tokenUSDRate);
  }

  function getUSDRaised() public view returns (uint) {
    return usdRaised;
  }

  function calculateMaxContributionUsd() public constant returns (uint) {
    return hardCap - usdRaised;
  }

  function calculateMaxTokensIssued() public constant returns (uint) {
    return hardCapToken - totalTokens;
  }

  function calculateMaxEthIssued() public constant returns (uint) {
    return hardCap.mul(ethUsdPrice) - usdRaised.mul(ethUsdPrice);
  }

  function getEthRaised() public view returns (uint) {
    return ethRaised;
  }

  function checkBalanceContract() internal view returns (uint) {
    return token.balanceOf(this);
  }

  function getContributorTokens(address contrib) public view returns (uint) {
    return registry.getContributionTokens(contrib);
  }

  function getContributorETH(address contrib) public view returns (uint) {
    return registry.getContributionETH(contrib);
  }

  function getContributorUSD(address contrib) public view returns (uint) {
    return registry.getContributionUSD(contrib);
  }

  function batchReturnUNT(uint _numberOfReturns) public onlyOwner whenNotPaused {
    require((now > endDate && usdRaised >= softCap )  || ( usdRaised >= hardCap)  );
    require(state == SaleState.ENDED);
    require(_numberOfReturns > 0);

    address currentParticipantAddress;

    for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
      currentParticipantAddress = registry.getContributorByIndex(nextContributorToTransferTokens);
      if (currentParticipantAddress == 0x0)
        return;

      if (!hasWithdrawedTokens[currentParticipantAddress] && registry.isActiveContributor(currentParticipantAddress)) {

        uint numberOfUNT = registry.getContributionTokens(currentParticipantAddress);

        if(token.transfer(currentParticipantAddress, numberOfUNT)) {
          TokensTransfered(currentParticipantAddress, numberOfUNT);
          withdrawedTokens += numberOfUNT;
          hasWithdrawedTokens[currentParticipantAddress] = true;
        }
      }

      nextContributorToTransferTokens += 1;
    }

  }

  function getTokens() public whenNotPaused {
    require((now > endDate && usdRaised >= softCap )  || ( usdRaised >= hardCap)  );
    require(state == SaleState.ENDED);
    require(!hasWithdrawedTokens[msg.sender] && registry.isActiveContributor(msg.sender));
    require(getTokenBalance() >= registry.getContributionTokens(msg.sender));

    uint numberOfUNT = registry.getContributionTokens(msg.sender);

    if(token.transfer(msg.sender, numberOfUNT)) {
      TokensTransfered(msg.sender, numberOfUNT);
      withdrawedTokens += numberOfUNT;
      hasWithdrawedTokens[msg.sender] = true;
    }

  }

  function getOverTokens() public onlyOwner {
    require(checkBalanceContract() > (totalTokens - withdrawedTokens));
    uint balance = checkBalanceContract() - (totalTokens - withdrawedTokens);
    if(balance > 0) {
      if(token.transfer(msg.sender, balance)) {
        TokensTransfered(msg.sender,  balance);
      }
    }
  }

   
  function refund() public whenNotPaused {
    require(state == SaleState.REFUND);
    require(registry.getContributionETH(msg.sender) > 0);
    require(!hasRefunded[msg.sender]);

    uint ethContributed = registry.getContributionETH(msg.sender);
    if (!msg.sender.send(ethContributed)) {
      ErrorSendingETH(msg.sender, ethContributed);
    } else {
      hasRefunded[msg.sender] = true;
      Refunded(msg.sender, ethContributed);
    }
  }

   
  function withdrawEth() public onlyOwner {
    require(state == SaleState.ENDED);
    uint bal = this.balance;
    hold.transfer(bal);
    hold.setInitialBalance(bal);
    WithdrawedEthToHold(bal);
  }

  function newCrowdsale() public onlyOwner {
    state = SaleState.NEW;
  }

   
  function startCrowdsale() public onlyOwner {
    require(now > startDate && now <= endDate);
    require(state == SaleState.NEW);

    statusI.setStatus(BuildingStatus.statusEnum.crowdsale);
    state = SaleState.SALE;
    CrowdsaleStarted(block.number);
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endDate || state == SaleState.ENDED;
  }

  function getTokenBalance() public constant returns (uint) {
    return token.balanceOf(this);
  }

  function getSoftCap() public view returns (uint) {
    return softCap;
  }

  function getHardCap() public view returns (uint) {
    return hardCap;
  }

  function getStartDate() public view returns (uint) {
    return startDate;
  }

  function getEndDate() public view returns (uint) {
    return endDate;
  }

  function getContributorAmount() public view returns (uint) {
    return registry.getContributorAmount();
  }

  function getWithdrawed(address contrib) public view returns (bool) {
    return hasWithdrawedTokens[contrib];
  }

  function getRefunded(address contrib) public view returns (bool) {
    return hasRefunded[contrib];
  }

  function addContributor(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote) public onlyPermitted {
    registry.addContributor(_contributor, _amount, _amusd, _tokens, _quote);
    ethRaised += _amount;
    usdRaised += _amusd;
    totalTokens += _tokens;
    ContributionAddedManual(_contributor, ethRaised, usdRaised, totalTokens, _quote);

  }

  function editContribution(address _contributor, uint _amount, uint _amusd, uint _tokens, uint _quote) public onlyPermitted {
    ethRaised -= registry.getContributionETH(_contributor);
    usdRaised -= registry.getContributionUSD(_contributor);
    totalTokens -= registry.getContributionTokens(_contributor);

    registry.editContribution(_contributor, _amount, _amusd, _tokens, _quote);
    ethRaised += _amount;
    usdRaised += _amusd;
    totalTokens += _tokens;
    ContributionAdded(_contributor, ethRaised, usdRaised, totalTokens, _quote);

  }

  function removeContributor(address _contributor) public onlyPermitted {
    registry.removeContribution(_contributor);
    ethRaised -= registry.getContributionETH(_contributor);
    usdRaised -= registry.getContributionUSD(_contributor);
    totalTokens -= registry.getContributionTokens(_contributor);
    ContributionRemoved(_contributor, ethRaised, usdRaised, totalTokens);
  }

}