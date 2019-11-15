pragma solidity ^0.4.15;


contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function Owned() { owner = msg.sender; }

    function isOwner(address addr) public returns(bool) { return addr == owner; }

    function transfer(address newOwner) public onlyOwner {
        if (newOwner != address(this)) {
            owner = newOwner;
        }
    }
}

contract Proxy is Owned {
    event Forwarded (address indexed destination, uint value, bytes data);
    event Received (address indexed sender, uint value);

    function () payable { Received(msg.sender, msg.value); }

    function forward(address destination, uint value, bytes data) public onlyOwner {
        require(destination.call.value(value)(data));
        Forwarded(destination, value, data);
    }
}


contract MetaIdentityManager {
    uint adminTimeLock;
    uint userTimeLock;
    uint adminRate;
    address relay;

    event LogIdentityCreated(
        address indexed identity,
        address indexed creator,
        address owner,
        address indexed recoveryKey);

    event LogOwnerAdded(
        address indexed identity,
        address indexed owner,
        address instigator);

    event LogOwnerRemoved(
        address indexed identity,
        address indexed owner,
        address instigator);

    event LogRecoveryChanged(
        address indexed identity,
        address indexed recoveryKey,
        address instigator);

    event LogMigrationInitiated(
        address indexed identity,
        address indexed newIdManager,
        address instigator);

    event LogMigrationCanceled(
        address indexed identity,
        address indexed newIdManager,
        address instigator);

    event LogMigrationFinalized(
        address indexed identity,
        address indexed newIdManager,
        address instigator);

    mapping(address => mapping(address => uint)) owners;
    mapping(address => address) recoveryKeys;
    mapping(address => mapping(address => uint)) limiter;
    mapping(address => uint) public migrationInitiated;
    mapping(address => address) public migrationNewAddress;

    modifier onlyAuthorized() {
        require(msg.sender == relay || checkMessageData(msg.sender));
        _;
    }

    modifier onlyOwner(address identity, address sender) {
        require(isOwner(identity, sender));
        _;
    }

    modifier onlyOlderOwner(address identity, address sender) {
        require(isOlderOwner(identity, sender));
        _;
    }

    modifier onlyRecovery(address identity, address sender) {
        require(recoveryKeys[identity] == sender);
        _;
    }

    modifier rateLimited(Proxy identity, address sender) {
        require(limiter[identity][sender] < (now - adminRate));
        limiter[identity][sender] = now;
        _;
    }

    modifier validAddress(address addr) {  
        require(addr != address(0));
        _;
    }

     
     
     
     
     
    function MetaIdentityManager(uint _userTimeLock, uint _adminTimeLock, uint _adminRate, address _relayAddress) {
        require(_adminTimeLock >= _userTimeLock);
        adminTimeLock = _adminTimeLock;
        userTimeLock = _userTimeLock;
        adminRate = _adminRate;
        relay = _relayAddress;
    }

     
     
     
     
    function createIdentity(address owner, address recoveryKey) public validAddress(recoveryKey) {
        Proxy identity = new Proxy();
        owners[identity][owner] = now - adminTimeLock;  
        recoveryKeys[identity] = recoveryKey;
        LogIdentityCreated(identity, msg.sender, owner,  recoveryKey);
    }

     
     
     
     
     
    function createIdentityWithCall(address owner, address recoveryKey, address destination, bytes data) public validAddress(recoveryKey) {
        Proxy identity = new Proxy();
        owners[identity][owner] = now - adminTimeLock;  
        recoveryKeys[identity] = recoveryKey;
        LogIdentityCreated(identity, msg.sender, owner,  recoveryKey);
        identity.forward(destination, 0, data);
    }

     
     
     
     
    function registerIdentity(address owner, address recoveryKey) public validAddress(recoveryKey) {
        require(recoveryKeys[msg.sender] == 0);  
        owners[msg.sender][owner] = now - adminTimeLock;  
        recoveryKeys[msg.sender] = recoveryKey;
        LogIdentityCreated(msg.sender, msg.sender, owner, recoveryKey);
    }

     
    function forwardTo(address sender, Proxy identity, address destination, uint value, bytes data) public onlyAuthorized onlyOwner(identity, sender){
        identity.forward(destination, value, data);
    }

     
    function addOwner(address sender, Proxy identity, address newOwner) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
        rateLimited(identity, sender)
    {
        require(!isOwner(identity, newOwner));
        owners[identity][newOwner] = now - userTimeLock;
        LogOwnerAdded(identity, newOwner, sender);
    }

     
    function addOwnerFromRecovery(address sender, Proxy identity, address newOwner) public
        onlyAuthorized
        onlyRecovery(identity, sender)
        rateLimited(identity, sender)
    {
        require(!isOwner(identity, newOwner));
        owners[identity][newOwner] = now;
        LogOwnerAdded(identity, newOwner, sender);
    }

     
    function removeOwner(address sender, Proxy identity, address owner) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
        rateLimited(identity, sender)
    {
         
        require(sender != owner);
        delete owners[identity][owner];
        LogOwnerRemoved(identity, owner, sender);
    }

     
    function changeRecovery(address sender, Proxy identity, address recoveryKey) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
        rateLimited(identity, sender)
        validAddress(recoveryKey)
    {
        recoveryKeys[identity] = recoveryKey;
        LogRecoveryChanged(identity, recoveryKey, sender);
    }

     
    function initiateMigration(address sender, Proxy identity, address newIdManager) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
    {
        migrationInitiated[identity] = now;
        migrationNewAddress[identity] = newIdManager;
        LogMigrationInitiated(identity, newIdManager, sender);
    }

     
    function cancelMigration(address sender, Proxy identity) public
        onlyAuthorized
        onlyOwner(identity, sender)
    {
        address canceledManager = migrationNewAddress[identity];
        delete migrationInitiated[identity];
        delete migrationNewAddress[identity];
        LogMigrationCanceled(identity, canceledManager, sender);
    }

     
     
     
    function finalizeMigration(address sender, Proxy identity) onlyAuthorized onlyOlderOwner(identity, sender) {
        require(migrationInitiated[identity] != 0 && migrationInitiated[identity] + adminTimeLock < now);
        address newIdManager = migrationNewAddress[identity];
        delete migrationInitiated[identity];
        delete migrationNewAddress[identity];
        identity.transfer(newIdManager);
        delete recoveryKeys[identity];
         
         
        delete owners[identity][sender];
        LogMigrationFinalized(identity, newIdManager, sender);
    }

     
     
    function checkMessageData(address a) internal constant returns (bool t) {
        if (msg.data.length < 36) return false;
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            t := eq(a, and(mask, calldataload(4)))
        }
    }

    function isOwner(address identity, address owner) public constant returns (bool) {
        return (owners[identity][owner] > 0 && (owners[identity][owner] + userTimeLock) <= now);
    }

    function isOlderOwner(address identity, address owner) public constant returns (bool) {
        return (owners[identity][owner] > 0 && (owners[identity][owner] + adminTimeLock) <= now);
    }

    function isRecovery(address identity, address recoveryKey) public constant returns (bool) {
        return recoveryKeys[identity] == recoveryKey;
    }
}