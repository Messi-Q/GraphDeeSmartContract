pragma solidity ^0.4.11;

 
contract MoacToken  {
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => uint256) redeem;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
    string public name = "MoacToken Token";
    string public symbol = "MOAC";
    uint public decimals = 18;

    uint public startBlock;  
    uint public endBlock;  

    address public founder = 0x0;
    address public owner = 0x0;

     
    address public signer = 0x0;

     
    uint256 public levelOneTokenNum = 30000000 * 10**18;  
    uint256 public levelTwoTokenNum = 50000000 * 10**18;  
    uint256 public levelThreeTokenNum = 75000000 * 10**18;  
    uint256 public levelFourTokenNum = 100000000 * 10**18;  
    
     
    uint256 public etherCap = 1000000 * 10**18;  
    uint public transferLockup = 370285; 
    uint public founderLockup = 86400; 
    
    uint256 public founderAllocation = 100 * 10**16; 
    bool public founderAllocated = false; 

    uint256 public saleTokenSupply = 0; 
    uint256 public saleEtherRaised = 0; 
    bool public halted = false; 

    event Donate(uint256 eth, uint256 fbt);
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event print(bytes32 msg);

    function MoacToken(address founderInput, address signerInput, uint startBlockInput, uint endBlockInput) {
        founder = founderInput;
        signer = signerInput;
        startBlock = startBlockInput;
        endBlock = endBlockInput;
        owner = msg.sender;
    }

     
    function price() constant returns(uint256) {
        if (totalSupply<levelOneTokenNum) return 1600;
        if (totalSupply>=levelOneTokenNum && totalSupply < levelTwoTokenNum) return 1000;
        if (totalSupply>=levelTwoTokenNum && totalSupply < levelThreeTokenNum) return 800;
        if (totalSupply>=levelThreeTokenNum && totalSupply < levelFourTokenNum) return 730;
        if (totalSupply>=levelFourTokenNum) return 680;
        return 1600;
    }

     
    function testPrice(uint256 currentSupply) constant returns(uint256) {
        if (currentSupply<levelOneTokenNum) return 1600;
        if (currentSupply>=levelOneTokenNum && currentSupply < levelTwoTokenNum) return 1000;
        if (currentSupply>=levelTwoTokenNum && currentSupply < levelThreeTokenNum) return 800;
        if (currentSupply>=levelThreeTokenNum && currentSupply < levelFourTokenNum) return 730;
        if (currentSupply>=levelFourTokenNum) return 680;
        return 1600;
    }


     
    function donate( bytes32 hash) payable {
        print(hash);
        if (block.number<startBlock || block.number>endBlock || (saleEtherRaised + msg.value)>etherCap || halted) throw;
        uint256 tokens = (msg.value * price());
        balances[msg.sender] = (balances[msg.sender] + tokens);
        totalSupply = (totalSupply + tokens);
        saleEtherRaised = (saleEtherRaised + msg.value);
        if (!founder.call.value(msg.value)()) throw;
        Donate(msg.value, tokens);
    }

     
    function allocateFounderTokens() {
        if (msg.sender!=founder) throw;
        if (block.number <= endBlock + founderLockup) throw;
        if (founderAllocated) throw;
        balances[founder] = (balances[founder] + saleTokenSupply * founderAllocation / (1 ether));
        totalSupply = (totalSupply + saleTokenSupply * founderAllocation / (1 ether));
        founderAllocated = true;
        AllocateFounderTokens(msg.sender);
    }

     
    function offlineDonate(uint256 offlineTokenNum, uint256 offlineEther) {
        if (msg.sender!=signer) throw;
        if (block.number >= endBlock) throw;  
        
         
        if( (totalSupply +offlineTokenNum) > totalSupply && (saleEtherRaised + offlineEther)>saleEtherRaised){
            totalSupply = (totalSupply + offlineTokenNum);
            balances[founder] = (balances[founder] + offlineTokenNum );
            saleEtherRaised = (saleEtherRaised + offlineEther);
        }
    }


     
    function offlineAdjust(uint256 offlineTokenNum, uint256 offlineEther) {
        if (msg.sender!=founder) throw;
        if (block.number >= endBlock) throw;  
        
         
        if( (totalSupply - offlineTokenNum) > 0 && (saleEtherRaised - offlineEther) > 0 && (balances[founder] - offlineTokenNum)>0){
            totalSupply = (totalSupply - offlineTokenNum);
            balances[founder] = (balances[founder] - offlineTokenNum );
            saleEtherRaised = (saleEtherRaised - offlineEther);
        }
    }


     
    function redeemBalanceOf(address _owner) constant returns (uint256 balance) {
        return redeem[_owner];
    }

     
    function redeemToken(uint256 tokenNum) {
        if (block.number <= (endBlock + transferLockup) && msg.sender!=founder) throw; 
        if( balances[msg.sender] < tokenNum ) throw;
        balances[msg.sender] = (balances[msg.sender] - tokenNum );
        redeem[msg.sender] += tokenNum;
    }

     
    function redeemRestore(address _to, uint256 tokenNum){
        if( msg.sender != founder) throw;
        if( redeem[_to] < tokenNum ) throw;

        redeem[_to] -= tokenNum;
        balances[_to] += tokenNum;
    }


     
    function halt() {
        if (msg.sender!=founder) throw;
        halted = true;
    }

    function unhalt() {
        if (msg.sender!=founder) throw;
        halted = false;
    }

     
    function kill() { 
        if (msg.sender == owner) suicide(owner); 
    }


     
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) throw;
        founder = newFounder;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (block.number <= (endBlock + transferLockup) && msg.sender!=founder) throw;

         
        if (balances[msg.sender] >= _value && (balances[_to] + _value) > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }

    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (block.number <= (endBlock + transferLockup) && msg.sender!=founder) throw;

         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && (balances[_to] + _value) > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

     
    function() {
        throw;
    }

}