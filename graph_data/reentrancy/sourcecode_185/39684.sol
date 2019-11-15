 
 
 
 
 
 

pragma solidity ^0.4.9;

 
contract EtherprisesLLC {
     
    address public seriesFactory;
     
    address public generalManager;
     
    address[] public series;
     
    string[] public prose;
     
    mapping (address => address) public latestSeriesForUser;
     
    mapping (address => uint) public expiresAt;
     
    mapping (bytes32 => address) public seriesByName;
     
    mapping (address => bytes32) public seriesByAddress;
    
     
    event AmendmentAdded (string newAmendment);
    event FeePaid (address which);
    event ManagerSet(address newManager);
    event FactorySet(address newFactory);
    event DepositMade(address where, uint amount);
    event SeriesCreated(address addr, uint id);
    
     
     
    function EtherprisesLLC() {
        generalManager = msg.sender;
    }
    
     
    modifier ifGeneralManager {
        if (msg.sender != generalManager)
            throw;

        _;
    }
    
     
    modifier ifSeries {
        if (expiresAt[msg.sender] == 0)
            throw;

        _;
    }
    
     
     
    function withdraw() ifGeneralManager {
        generalManager.send(this.balance);
    }
    
     
     
     
     
    function isExpired(address addr) constant returns (bool) {
        if (expiresAt[addr] > now)
            return false;
        else
            return true;
    }
    
     
     
     
     
    function addAmendment(string newAmendment) ifGeneralManager {
         
         
        prose.push(newAmendment);
        
        AmendmentAdded(newAmendment);
    }
    
     
     
    function payFee() ifSeries payable returns (bool) {
         
        if (msg.value != 1 ether)
            throw;
            
        expiresAt[msg.sender] += 1 years;
        
        FeePaid(msg.sender);
        return true;
    }
    
     
     
     
    function setManager(address newManger) ifGeneralManager {
        generalManager = newManger;
        
        ManagerSet(newManger);
    }
    
     
     
    function setFactory(address newFactory) ifGeneralManager {
        seriesFactory = newFactory;
        
        FactorySet(newFactory);
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createSeries(bytes name, uint shares, string industry, string symbol, address extraContract) payable returns (address seriesAddress,uint seriesId) {
        seriesId = series.length;
        
        var(latestAddress, latestName) = SeriesFactory(seriesFactory).createSeries.value(msg.value)(seriesId, name, shares, industry, symbol, msg.sender, extraContract);
        if (latestAddress == 0)
            throw;

        if (latestName > 0)
            if (seriesByName[latestName] == 0)
                seriesByName[latestName] = latestAddress;
            else
                throw;

        series.push(latestAddress);
        expiresAt[latestAddress] = now + 1 years;
        latestSeriesForUser[msg.sender] = latestAddress;
        seriesByAddress[latestAddress] = latestName;
        
        SeriesCreated(latestAddress, seriesId);
        return (latestAddress, seriesId);
    }
    
     
     
     
     
    function addr(bytes32 _name) constant returns(address o_address) {
        return seriesByName[_name];
    }
    
     
     
     
     
     
    function name(address _owner) constant returns(bytes32 o_name){
        return seriesByAddress[_owner];
    }
    
     
     
    function () payable {
        if (msg.data.length > 0) {
            createSeries(msg.data, 0, "", "", 0x0);
        } else if (latestSeriesForUser[msg.sender] != 0) {
             
            if (latestSeriesForUser[msg.sender].call.value(msg.value)())
                DepositMade(latestSeriesForUser[msg.sender], msg.value);
        } else {
            createSeries("", 0, "", "", 0x0);
        }
    }
}

 
 
 
contract SeriesFactory {
    address public seriesFactory;
    address public owner;

    function createSeries (uint seriesId,bytes name,uint shares,string industry,string symbol,address manager,address extraContract) payable returns (address addr,bytes32 newName) {
        address newSeries;
        bytes32 _newName;

        return (newSeries, _newName);
    }
}