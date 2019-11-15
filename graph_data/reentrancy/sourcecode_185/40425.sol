contract MyEtherBank
{

    address private _owner;
    uint256 private _bankDonationsBalance = 0;
    bool private _connectBankAccountToNewOwnerAddressEnabled = true;

     
    struct BankAccount
    {
         
        bool passwordSha3HashSet;
        uint32 number; 
        uint32 passwordAttempts;
        uint256 balance;
        address owner;       
        bytes32 passwordSha3Hash;   
        mapping(bytes32 => bool) passwordSha3HashesUsed;
    }   

    struct BankAccountAddress
    {
        bool accountSet;
        uint32 accountNumber;  
    }
 
    uint32 private _totalBankAccounts = 0;
    BankAccount[] private _bankAccountsArray; 
    mapping(address => BankAccountAddress) private _bankAccountAddresses;  


     

    function MyEtherBank() public
    {
         
        _owner = msg.sender; 
    }


     

     
    event event_donationMadeToBank_ThankYou(uint256 donationAmount);
    event event_getBankDonationsBalance(uint256 donationBalance);
    event event_bankDonationsWithdrawn(uint256 donationsAmount);

     
    event event_bankAccountOpened_Successful(address indexed bankAccountOwner, uint32 indexed bankAccountNumber, uint256 indexed depositAmount);
    event event_getBankAccountNumber_Successful(uint32 indexed bankAccountNumber);
    event event_getBankAccountBalance_Successful(uint32 indexed bankAccountNumber, uint256 indexed balance);
    event event_depositMadeToBankAccount_Successful(uint32 indexed bankAccountNumber, uint256 indexed depositAmount); 
    event event_depositMadeToBankAccount_Failed(uint32 indexed bankAccountNumber, uint256 indexed depositAmount); 
    event event_depositMadeToBankAccountFromDifferentAddress_Successful(uint32 indexed bankAccountNumber, address indexed addressFrom, uint256 indexed depositAmount);
    event event_depositMadeToBankAccountFromDifferentAddress_Failed(uint32 indexed bankAccountNumber, address indexed addressFrom, uint256 indexed depositAmount);
    event event_withdrawalMadeFromBankAccount_Successful(uint32 indexed bankAccountNumber, uint256 indexed withdrawalAmount); 
    event event_withdrawalMadeFromBankAccount_Failed(uint32 indexed bankAccountNumber, uint256 indexed withdrawalAmount); 
    event event_transferMadeFromBankAccountToAddress_Successful(uint32 indexed bankAccountNumber, uint256 indexed transferalAmount, address indexed destinationAddress); 
    event event_transferMadeFromBankAccountToAddress_Failed(uint32 indexed bankAccountNumber, uint256 indexed transferalAmount, address indexed destinationAddress); 

     
    event event_securityConnectingABankAccountToANewOwnerAddressIsDisabled();
    event event_securityHasPasswordSha3HashBeenAddedToBankAccount_Yes(uint32 indexed bankAccountNumber);
    event event_securityHasPasswordSha3HashBeenAddedToBankAccount_No(uint32 indexed bankAccountNumber);
	event event_securityPasswordSha3HashAddedToBankAccount_Successful(uint32 indexed bankAccountNumber);
    event event_securityPasswordSha3HashAddedToBankAccount_Failed_PasswordHashPreviouslyUsed(uint32 indexed bankAccountNumber);
    event event_securityBankAccountConnectedToNewAddressOwner_Successful(uint32 indexed bankAccountNumber, address indexed newAddressOwner);
    event event_securityBankAccountConnectedToNewAddressOwner_Failed_PasswordHashHasNotBeenAddedToBankAccount(uint32 indexed bankAccountNumber);
    event event_securityBankAccountConnectedToNewAddressOwner_Failed_SentPasswordDoesNotMatchAccountPasswordHash(uint32 indexed bankAccountNumber, uint32 indexed passwordAttempts);
    event event_securityGetNumberOfAttemptsToConnectBankAccountToANewOwnerAddress(uint32 indexed bankAccountNumber, uint32 indexed attempts);


     

    modifier modifier_isContractOwner()
    { 
         
        if (msg.sender != _owner)
        {
            throw;       
        }
        _;
    }

    modifier modifier_doesSenderHaveABankAccount() 
    { 
         
        if (_bankAccountAddresses[msg.sender].accountSet == false)
        {
            throw;
        }
        else
        {
             
            uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
            if (msg.sender != _bankAccountsArray[accountNumber_].owner)
            {
                 
                throw;        
            }
        }
        _;
    }

    modifier modifier_wasValueSent()
    { 
         
        if (msg.value > 0)
        {
             
            throw;        
        }
        _;
    }


     

    function Donate() public
    {
        if (msg.value > 0)
        {
            _bankDonationsBalance += msg.value;
            event_donationMadeToBank_ThankYou(msg.value);
        }
    }

    function BankOwner_GetDonationsBalance() public      
        modifier_isContractOwner()
        modifier_wasValueSent()
        returns (uint256)
    {
        event_getBankDonationsBalance(_bankDonationsBalance);
  	    return _bankDonationsBalance;
    }

    function BankOwner_WithdrawDonations() public modifier_isContractOwner()  modifier_wasValueSent() { 
        if (_bankDonationsBalance > 0) {
            uint256 amount_ = _bankDonationsBalance;
            _bankDonationsBalance = 0;

            if (msg.sender.send(amount_)) {
                event_bankDonationsWithdrawn(amount_);
            }  else if (msg.sender.call.value(amount_)())  {
                event_bankDonationsWithdrawn(amount_);
            }  else {
                _bankDonationsBalance = amount_;
            }
        }
    }

    function BankOwner_EnableConnectBankAccountToNewOwnerAddress() public
        modifier_isContractOwner()
    { 
        if (_connectBankAccountToNewOwnerAddressEnabled == false)
        {
            _connectBankAccountToNewOwnerAddressEnabled = true;
        }
    }

    function  BankOwner_DisableConnectBankAccountToNewOwnerAddress() public
        modifier_isContractOwner()
    { 
        if (_connectBankAccountToNewOwnerAddressEnabled)
        {
            _connectBankAccountToNewOwnerAddressEnabled = false;
        }
    }


     

     
    function OpenBankAccount() public
        returns (uint32 newBankAccountNumber) 
    {
         
        if (_bankAccountAddresses[msg.sender].accountSet)
        {
            throw;
        }

         
        newBankAccountNumber = _totalBankAccounts;

         
        _bankAccountsArray.push( 
            BankAccount(
            {
                passwordSha3HashSet: false,
                passwordAttempts: 0,
                number: newBankAccountNumber,
                balance: 0,
                owner: msg.sender,
                passwordSha3Hash: "0"
            }
            ));

         
        bytes32 passwordHash_ = sha3("password");
        _bankAccountsArray[newBankAccountNumber].passwordSha3HashesUsed[passwordHash_] = true;
        passwordHash_ = sha3("Password");
        _bankAccountsArray[newBankAccountNumber].passwordSha3HashesUsed[passwordHash_] = true;

         
        _bankAccountAddresses[msg.sender].accountSet = true;
        _bankAccountAddresses[msg.sender].accountNumber = newBankAccountNumber;

         
        if (msg.value > 0)
        {         
            _bankAccountsArray[newBankAccountNumber].balance += msg.value;
        }

         
        _totalBankAccounts++;

         
        event_bankAccountOpened_Successful(msg.sender, newBankAccountNumber, msg.value);
        return newBankAccountNumber;
    }

     
    function GetBankAccountNumber() public      
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (uint32)
    {
        event_getBankAccountNumber_Successful(_bankAccountAddresses[msg.sender].accountNumber);
	    return _bankAccountAddresses[msg.sender].accountNumber;
    }

    function GetBankAccountBalance() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (uint256)
    {   
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        event_getBankAccountBalance_Successful(accountNumber_, _bankAccountsArray[accountNumber_].balance);
        return _bankAccountsArray[accountNumber_].balance;
    }


     

    function DepositToBankAccount() public
        modifier_doesSenderHaveABankAccount()
        returns (bool)
    {
         
        if (msg.value > 0)
        {
            uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

             
            if ((_bankAccountsArray[accountNumber_].balance + msg.value) < _bankAccountsArray[accountNumber_].balance)
            {
                throw;
            }

            _bankAccountsArray[accountNumber_].balance += msg.value; 
            event_depositMadeToBankAccount_Successful(accountNumber_, msg.value);
            return true;
        }
        else
        {
            event_depositMadeToBankAccount_Failed(accountNumber_, msg.value);
            return false;
        }
    }

    function DepositToBankAccountFromDifferentAddress(uint32 bankAccountNumber) public
        returns (bool)
    {
         
        if (bankAccountNumber >= _totalBankAccounts)
        {
           event_depositMadeToBankAccountFromDifferentAddress_Failed(bankAccountNumber, msg.sender, msg.value);
           return false;     
        }    
            
         
        if (msg.value > 0)
        {   
             
            if ((_bankAccountsArray[bankAccountNumber].balance + msg.value) < _bankAccountsArray[bankAccountNumber].balance)
            {
                throw;
            }

            _bankAccountsArray[bankAccountNumber].balance += msg.value; 
            event_depositMadeToBankAccountFromDifferentAddress_Successful(bankAccountNumber, msg.sender, msg.value);
            return true;
        }
        else
        {
            event_depositMadeToBankAccountFromDifferentAddress_Failed(bankAccountNumber, msg.sender, msg.value);
            return false;
        }
    }
    

     

    function WithdrawAmountFromBankAccount(uint256 amount) public modifier_doesSenderHaveABankAccount()  modifier_wasValueSent()  returns (bool) {
        bool withdrawalSuccessful_ = false;
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

         
        if (amount > 0 && _bankAccountsArray[accountNumber_].balance >= amount)  {
             
            _bankAccountsArray[accountNumber_].balance -= amount;

             
            if (msg.sender.send(amount))   {
 	            withdrawalSuccessful_ = true;
            }
            else if (msg.sender.call.value(amount)()) {  
                withdrawalSuccessful_ = true;
            }  else {
                 
                _bankAccountsArray[accountNumber_].balance += amount;
            }
        }

        if (withdrawalSuccessful_)  {
            event_withdrawalMadeFromBankAccount_Successful(accountNumber_, amount); 
            return true;
        }  else {
            event_withdrawalMadeFromBankAccount_Failed(accountNumber_, amount); 
            return false;
        }
    }

    function WithdrawFullBalanceFromBankAccount() public modifier_doesSenderHaveABankAccount()  modifier_wasValueSent()  returns (bool)  {
        bool withdrawalSuccessful_ = false;
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 
        uint256 fullBalance_ = 0;

         
        if (_bankAccountsArray[accountNumber_].balance > 0)   {
            fullBalance_ = _bankAccountsArray[accountNumber_].balance;

             
            _bankAccountsArray[accountNumber_].balance = 0;

             
            if (msg.sender.send(fullBalance_))   {
 	            withdrawalSuccessful_ = true;
            }else 
			  if (msg.sender.call.value(fullBalance_)())  {  
                withdrawalSuccessful_ = true;
            } else {
                 
                _bankAccountsArray[accountNumber_].balance = fullBalance_;
            }
        }  

        if (withdrawalSuccessful_)  {
            event_withdrawalMadeFromBankAccount_Successful(accountNumber_, fullBalance_); 
            return true;
        }  else {
            event_withdrawalMadeFromBankAccount_Failed(accountNumber_, fullBalance_); 
            return false;
        }
    }

    function TransferAmountFromBankAccountToAddress(uint256 amount, address destinationAddress) public  modifier_doesSenderHaveABankAccount()  modifier_wasValueSent()  returns (bool) {
        bool transferSuccessful_ = false; 
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;   
        if (amount > 0 && _bankAccountsArray[accountNumber_].balance >= amount)  {
             
            _bankAccountsArray[accountNumber_].balance -= amount; 

             
            if (destinationAddress.send(amount))  {
 	            transferSuccessful_ = true;
            } else if (destinationAddress.call.value(amount)())      {  
                transferSuccessful_ = true;
            } else {
                 
                _bankAccountsArray[accountNumber_].balance += amount;
            }
        }  

        if (transferSuccessful_)  {
            event_transferMadeFromBankAccountToAddress_Successful(accountNumber_, amount, destinationAddress); 
            return true;
        } else {
            event_transferMadeFromBankAccountToAddress_Failed(accountNumber_, amount, destinationAddress); 
            return false;
        }
    }


     

    function Security_HasPasswordSha3HashBeenAddedToBankAccount() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

         
        if (_bankAccountsArray[accountNumber_].passwordSha3HashSet)
        {
            event_securityHasPasswordSha3HashBeenAddedToBankAccount_Yes(accountNumber_);
            return true;
        }
        else
        {
            event_securityHasPasswordSha3HashBeenAddedToBankAccount_No(accountNumber_);
            return false;
        }
    }

    function Security_AddPasswordSha3HashToBankAccount(bytes32 sha3Hash) public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
         
         
         
         
         
         
            
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

         
        if (_bankAccountsArray[accountNumber_].passwordSha3HashesUsed[sha3Hash] == true)
        {
            event_securityPasswordSha3HashAddedToBankAccount_Failed_PasswordHashPreviouslyUsed(accountNumber_);
            return false;        
        }

         
        _bankAccountsArray[accountNumber_].passwordSha3HashSet = true;
        _bankAccountsArray[accountNumber_].passwordSha3Hash = sha3Hash;
        _bankAccountsArray[accountNumber_].passwordSha3HashesUsed[sha3Hash] = true;

         
        _bankAccountsArray[accountNumber_].passwordAttempts = 0;

        event_securityPasswordSha3HashAddedToBankAccount_Successful(accountNumber_);
        return true;
    }

    function Security_ConnectBankAccountToNewOwnerAddress(uint32 bankAccountNumber, string password) public
        modifier_wasValueSent()
        returns (bool)
    {
         
         
         
         
         
         

         
        if (_connectBankAccountToNewOwnerAddressEnabled == false)
        {
            event_securityConnectingABankAccountToANewOwnerAddressIsDisabled();
            return false;        
        }

         
        if (bankAccountNumber >= _totalBankAccounts)
        {
            return false;     
        }    

         
        if (_bankAccountAddresses[msg.sender].accountSet)
        {
             
            return false;
        }

         
        if (_bankAccountsArray[bankAccountNumber].passwordSha3HashSet == false)
        {
            event_securityBankAccountConnectedToNewAddressOwner_Failed_PasswordHashHasNotBeenAddedToBankAccount(bankAccountNumber);
            return false;           
        }

         
        bytes memory passwordString = bytes(password);
        if (sha3(passwordString) != _bankAccountsArray[bankAccountNumber].passwordSha3Hash)
        {
             
            _bankAccountsArray[bankAccountNumber].passwordAttempts++;  
            event_securityBankAccountConnectedToNewAddressOwner_Failed_SentPasswordDoesNotMatchAccountPasswordHash(bankAccountNumber, _bankAccountsArray[bankAccountNumber].passwordAttempts); 
            return false;        
        }

         
        _bankAccountsArray[bankAccountNumber].owner = msg.sender;
        _bankAccountAddresses[msg.sender].accountSet = true;
        _bankAccountAddresses[msg.sender].accountNumber = bankAccountNumber;

         
        _bankAccountsArray[bankAccountNumber].passwordSha3HashSet = false;
        _bankAccountsArray[bankAccountNumber].passwordSha3Hash = "0";
       
         
        _bankAccountsArray[bankAccountNumber].passwordAttempts = 0;

        event_securityBankAccountConnectedToNewAddressOwner_Successful(bankAccountNumber, msg.sender);
        return true;
    }

    function Security_GetNumberOfAttemptsToConnectBankAccountToANewOwnerAddress() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (uint64)
    {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 
        event_securityGetNumberOfAttemptsToConnectBankAccountToANewOwnerAddress(accountNumber_, _bankAccountsArray[accountNumber_].passwordAttempts);
        return _bankAccountsArray[accountNumber_].passwordAttempts;
    }


     

    function() 
    {    
         
        if (_bankAccountAddresses[msg.sender].accountSet)
        {
             
            uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
            address accountOwner_ = _bankAccountsArray[accountNumber_].owner;
            if (msg.sender == accountOwner_) 
            {
                 
                if (msg.value > 0)
                {                
                     
                    if ((_bankAccountsArray[accountNumber_].balance + msg.value) < _bankAccountsArray[accountNumber_].balance)
                    {
                        throw;
                    }
 
                     
                    _bankAccountsArray[accountNumber_].balance += msg.value;
                    event_depositMadeToBankAccount_Successful(accountNumber_, msg.value);
                }
                else
                {
                    throw;
                }
            }
            else
            {
                 
                throw;
            }
        }
        else
        {
             
            OpenBankAccount();
        }
    }
}