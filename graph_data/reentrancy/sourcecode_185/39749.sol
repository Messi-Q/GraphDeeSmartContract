pragma solidity ^0.4.2;

 
contract token {

         
    function transfer(address _receiver, uint _amount) returns (bool success) { }

          
    function priviledgedAddressBurnUnsoldCoins(){ }

}

 
contract owned {

    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function ownerTransferOwnership(address newOwner)
        onlyOwner
    {
        owner = newOwner;
    }

}

 
contract DSSafeAddSub {

    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) throw;
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) throw;
        return a - b;
    } 

}

 
contract EtherollCrowdfund is owned, DSSafeAddSub {

         
    modifier onlyAfterDeadline() { 
        if (now < deadline) throw;
        _; 
    }

         
    modifier isEmergency() { 
        if (!emergency) throw;
        _; 
    } 

     
    uint public fundingGoal;
     
    uint public weekTwoPriceRiseBegin = now + 10080 * 1 minutes;    
     
    address public bankRollBeneficiary;      
     
    address public etherollBeneficiary;         
     
    uint public amountRaised;
     
    uint public deadline;
     
    uint public price = 10000000000000000;
     
    token public tokenReward;
     
    bool public crowdsaleClosed = false;  
     
    uint public bankrollBeneficiaryAmount;
         
    uint public etherollBeneficiaryAmount;
     
    mapping (address => uint) public balanceOf; 
      
    bool public fundingGoalReached = false;   
     
    bool public emergency = false; 

     
    event LogFundTransfer(address indexed Backer, uint indexed Amount, bool indexed IsContribution);  
    event LogGoalReached(address indexed Beneficiary, uint indexed AmountRaised);       

       
    function EtherollCrowdfund(
                 
        address _ifSuccessfulSendToBeneficiary,
         
        address _ifSuccessfulSendToEtheroll,
         
        uint _fundingGoalInEthers,
         
        uint _durationInMinutes,
         
        token _addressOfTokenUsedAsReward
    ) {
        bankRollBeneficiary = _ifSuccessfulSendToBeneficiary;
        etherollBeneficiary = _ifSuccessfulSendToEtheroll;
        fundingGoal = _fundingGoalInEthers * 1 ether;
        deadline = now + _durationInMinutes * 1 minutes;
        tokenReward = token(_addressOfTokenUsedAsReward);
    }
  
           
    function () payable {

         
        if(now > deadline) crowdsaleClosed = true;  

         
        if (crowdsaleClosed) throw;

                 
        if (msg.value == 0) throw;      

         
        if(now < weekTwoPriceRiseBegin) {
                      
             
            if(tokenReward.transfer(msg.sender, ((msg.value*price)/price)*2)) {
                LogFundTransfer(msg.sender, msg.value, true); 
            } else {
                throw;
            }

        }else{
             
            if(tokenReward.transfer(msg.sender, (msg.value*price)/price)) {
                LogFundTransfer(msg.sender, msg.value, true); 
            } else {
                throw;
            }            

        } 

         
        amountRaised = safeAdd(amountRaised, msg.value);          

           
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value);

    }    

          
    function safeWithdraw() public onlyAfterDeadline {

        if (amountRaised >= fundingGoal){
             
            fundingGoalReached = true;
                         
            LogGoalReached(bankRollBeneficiary, amountRaised);           
        }    
            
         
        crowdsaleClosed = true;  
                        
         
        if (!fundingGoalReached) {
            calcRefund(msg.sender);
        }
        
                 
        if (msg.sender == owner && fundingGoalReached) {

             
            bankrollBeneficiaryAmount = (this.balance*80)/100;   

                   
            if (bankRollBeneficiary.send(bankrollBeneficiaryAmount)) {  

                               
                LogFundTransfer(bankRollBeneficiary, bankrollBeneficiaryAmount, false);
            
                 
                etherollBeneficiaryAmount = this.balance;                  

                 
                if(!etherollBeneficiary.send(etherollBeneficiaryAmount)) throw;

                         
                LogFundTransfer(etherollBeneficiary, etherollBeneficiaryAmount, false);                 

            } else {

                 
                fundingGoalReached = false;

            }
        }
    }  

          
    function calcRefund(address _addressToRefund) internal {
        uint amount = balanceOf[_addressToRefund];
        balanceOf[_addressToRefund] = 0;
        if (amount > 0) {
            if (_addressToRefund.call.value(amount)()) {
                LogFundTransfer(_addressToRefund, amount, false);
            } else {
                balanceOf[_addressToRefund] = amount;
            }
        } 
    }     
   

          
    function emergencyWithdraw() public isEmergency {
         
        calcRefund(msg.sender);
    }        

         
    function ownerSetEmergencyStatus(bool _newEmergencyStatus) public onlyOwner {
         
        crowdsaleClosed = _newEmergencyStatus;
         
        emergency = _newEmergencyStatus;        
    } 

           
    function ownerBurnUnsoldTokens() onlyOwner onlyAfterDeadline {
        tokenReward.priviledgedAddressBurnUnsoldCoins();
    }         


}