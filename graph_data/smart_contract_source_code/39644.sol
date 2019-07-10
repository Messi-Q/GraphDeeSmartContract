pragma solidity ^0.4.2;

contract AddressOwnershipVerification {
    mapping(address => mapping (uint32 => address)) _requests;         
    mapping(address => mapping (address => uint32)) _requestsReverse;  
    mapping(address => mapping (address => uint32)) _verifications;    

    event RequestEvent(address indexed transactor, address indexed transactee, uint32 indexed deposit);       
    event RemoveRequestEvent(address indexed transactor, address indexed transactee);                         
    event VerificationEvent(address indexed transactor, address indexed transactee, uint32 indexed deposit);  
    event RevokeEvent(address indexed transactor, address indexed transactee, uint32 indexed deposit);        

    function AddressOwnershipVerification() {}

     
    function () payable {
        uint32 value = uint32(msg.value);

        if (!_requestExists(msg.sender, value)) {
            throw;
        }

         
        address transactor = _requests[msg.sender][value];

         
        _saveVerification(transactor, msg.sender, value);

         
        _deleteRequest(transactor, msg.sender);

        VerificationEvent(transactor, msg.sender, value);
    }

     
    function request(address transactee, uint32 deposit) {
         
        if (transactee == msg.sender) {
            throw;
        }

         
        if (deposit == 0) {
            throw;
        }

         
        if(verify(msg.sender, transactee)) {
            throw;
        }

         
        if (_requestExists(transactee, deposit)) {
            throw;
        }

        if (_requestExistsReverse(msg.sender, transactee)) {
            throw;
        }

        _saveRequest(msg.sender, transactee, deposit);

        RequestEvent(msg.sender, transactee, deposit);
    }

     
    function getRequest(address transactor, address transactee) returns (uint32 deposit) {
        return _requestsReverse[transactee][transactor];
    }

     
    function removeRequest(address transactor, address transactee) returns (uint32) {
         
        if (msg.sender != transactor && msg.sender != transactee) {
            throw;
        }

        _deleteRequest(transactor, transactee);

        RemoveRequestEvent(transactor, transactee);
    }

     
    function verify(address transactor, address transactee) returns (bool) {
        return _verifications[transactor][transactee] != 0;
    }

     
     
    function revoke(address transactor, address transactee) {
         
        if (msg.sender != transactor && msg.sender != transactee) { throw; }

         
        if(!verify(transactor, transactee)) { throw; }

        uint32 deposit = _verifications[transactor][transactee];

        delete _verifications[transactor][transactee];

        if (!transactee.call.value(deposit).gas(23000)()) {  throw;  }

        RevokeEvent(transactor, transactee, deposit);
    }

     
    function _saveRequest(address transactor, address transactee, uint32 deposit) internal {
        _requests[transactee][deposit] = transactor;
        _requestsReverse[transactee][transactor] = deposit;
    }

     
    function _deleteRequest(address transactor, address transactee) internal {
        uint32 deposit = _requestsReverse[transactee][transactor];

        delete _requests[transactee][deposit];
        delete _requestsReverse[transactee][transactor];
    }

     
    function _requestExists(address transactee, uint32 deposit) internal returns(bool) {
        return _requests[transactee][deposit] != 0x0000000000000000000000000000000000000000;
    }

     
    function _requestExistsReverse(address transactor, address transactee) internal returns(bool) {
        return _requestsReverse[transactee][transactor] != 0;
    }

     
    function _saveVerification(address transactor, address transactee, uint32 deposit) internal {
        _verifications[transactor][transactee] = deposit;
    }
}