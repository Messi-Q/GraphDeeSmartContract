contract DaoAccount
{


	uint256 tokenBalance;  
    address owner;
	address daoChallenge;  
	uint256 tokenPrice;

   
   
  address challengeOwner;


	modifier noEther() {if (msg.value > 0) throw; _;}

	modifier onlyOwner() {if (owner != msg.sender) throw; _;}

	modifier onlyDaoChallenge() {if (daoChallenge != msg.sender) throw; _;}

	modifier onlyChallengeOwner() {if (challengeOwner != msg.sender) throw; _;}


  function DaoAccount (address _owner, uint256 _tokenPrice, address _challengeOwner) noEther {
    owner = _owner;
		tokenPrice = _tokenPrice;
    daoChallenge = msg.sender;
		tokenBalance = 0;

     
    challengeOwner = _challengeOwner;
	}

	function () {
		throw;
	}

	 

	 

	function getTokenBalance() constant returns (uint256 tokens) {
		return tokenBalance;
	}

	function buyTokens() onlyDaoChallenge returns (uint256 tokens) {
		uint256 amount = msg.value;

		 
		if (amount == 0) throw;

		 
		if (amount % tokenPrice != 0) throw;

		tokens = amount / tokenPrice;

		tokenBalance += tokens;

		return tokens;
	}

	function withdraw(uint256 tokens) noEther onlyDaoChallenge {
		if (tokens == 0 || tokenBalance == 0 || tokenBalance < tokens) throw;
		tokenBalance -= tokens;
		if(!owner.call.value(tokens * tokenPrice)()) throw;
	}

	 
	function terminate() noEther onlyChallengeOwner {
		suicide(challengeOwner);
	}
}

contract DaoChallenge
{
	 

	uint256 constant public tokenPrice = 1000000000000000;  

	 

	event notifyTerminate(uint256 finalBalance);

	event notifyNewAccount(address owner, address account);
	event notifyBuyToken(address owner, uint256 tokens, uint256 price);
	event notifyWithdraw(address owner, uint256 tokens);

	 

	mapping (address => DaoAccount) public daoAccounts;

	 

	 
	address challengeOwner;

	 

	modifier noEther() {if (msg.value > 0) throw; _;}

	modifier onlyChallengeOwner() {if (challengeOwner != msg.sender) throw; _;}

	 

	function DaoChallenge () {
		challengeOwner = msg.sender;  
	}

	function () noEther {
	}

	 

	function accountFor (address accountOwner, bool createNew) private returns (DaoAccount) {
		DaoAccount account = daoAccounts[accountOwner];

		if(account == DaoAccount(0x00) && createNew) {
			account = new DaoAccount(accountOwner, tokenPrice, challengeOwner);
			daoAccounts[accountOwner] = account;
			notifyNewAccount(accountOwner, address(account));
		}

		return account;
	}

	 

	function getTokenBalance () constant noEther returns (uint256 tokens) {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) return 0;
		return account.getTokenBalance();
	}

	function buyTokens () returns (uint256 tokens) {
	  DaoAccount account = accountFor(msg.sender, true);
		tokens = account.buyTokens.value(msg.value)();

		notifyBuyToken(msg.sender, tokens, msg.value);
		return tokens;
 	}

	function withdraw(uint256 tokens) noEther {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) throw;

		account.withdraw(tokens);
		notifyWithdraw(msg.sender, tokens);
	}

	 
	function terminate() noEther onlyChallengeOwner {
		notifyTerminate(this.balance);
		suicide(challengeOwner);
	}
}