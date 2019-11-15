contract DaoAccount
{
	 

	uint256 constant tokenPrice = 1000000000000000;  

	 

	 
	
	 

  uint256 public tokenBalance;  

	 

  address owner;         
	address daoChallenge;  

   
   
  address challengeOwner;

	 

	modifier noEther() {if (msg.value > 0) throw; _;}

	modifier onlyOwner() {if (owner != msg.sender) throw; _;}

	modifier onlyChallengeOwner() {if (challengeOwner != msg.sender) throw; _;}

	 

  function DaoAccount (address _owner, address _challengeOwner) {
    owner = _owner;
    daoChallenge = msg.sender;

     
    challengeOwner = _challengeOwner;
	}

     
	function () onlyOwner returns (uint256 newBalance){
		uint256 amount = msg.value;

		 
		if (amount % tokenPrice != 0) {
			throw;
		}

    uint256 tokens = amount / tokenPrice;

		tokenBalance += tokens;

    return tokenBalance;
	}
 
	function withdrawEtherOrThrow(uint256 amount) private {
        if (msg.sender != owner) throw;
		bool result = owner.call.value(amount)();
		if (!result) { throw;}
	}

	 

	function refund() noEther onlyOwner {
		if (tokenBalance == 0) throw;
		tokenBalance = 0;
		withdrawEtherOrThrow(tokenBalance * tokenPrice);
	}

	 
	function terminate() noEther onlyChallengeOwner {
		suicide(challengeOwner);
	}
}
contract DaoChallenge
{
	 

	 

	 

	event notifyTerminate(uint256 finalBalance);

	 

	 

	 
	address owner;

	mapping (address => DaoAccount) private daoAccounts;

	 

	modifier noEther() {if (msg.value > 0) throw; _;}

	modifier onlyOwner() {if (owner != msg.sender) throw; _;}

	 

	function DaoChallenge () {
		owner = msg.sender;  
	}

	function () noEther {
	}

	 

	 

	 

	function createAccount () noEther returns (DaoAccount account) {
		address accountOwner = msg.sender;
		address challengeOwner = owner;  

		 
		if(daoAccounts[accountOwner] != DaoAccount(0x00)) throw;

		daoAccounts[accountOwner] = new DaoAccount(accountOwner, challengeOwner);
		return daoAccounts[accountOwner];
	}

	function myAccount () noEther returns (DaoAccount) {
		address accountOwner = msg.sender;
		return daoAccounts[accountOwner];
	}

	 
	function terminate() noEther onlyOwner {
		notifyTerminate(this.balance);
		suicide(owner);
	}
}