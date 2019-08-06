contract AbstractDaoChallenge {
	function isMember (DaoAccount account, address allegedOwnerAddress) returns (bool);
}

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





	function getOwnerAddress() constant returns (address ownerAddress) {
		return owner;
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

	function transfer(uint256 tokens, DaoAccount recipient) noEther onlyDaoChallenge {
		if (tokens == 0 || tokenBalance == 0 || tokenBalance < tokens) throw;
		tokenBalance -= tokens;
		recipient.receiveTokens.value(tokens * tokenPrice)(tokens);
	}

	function receiveTokens(uint256 tokens) {

		DaoAccount sender = DaoAccount(msg.sender);
		if (!AbstractDaoChallenge(daoChallenge).isMember(sender, sender.getOwnerAddress())) throw;

		uint256 amount = msg.value;


		if (amount == 0) throw;

		if (amount / tokenPrice != tokens) throw;

		tokenBalance += tokens;
	}


	function terminate() noEther onlyChallengeOwner {
		suicide(challengeOwner);
	}
}
contract DaoChallenge
{





	event notifyTerminate(uint256 finalBalance);
	event notifyTokenIssued(uint256 n, uint256 price, uint deadline);

	event notifyNewAccount(address owner, address account);
	event notifyBuyToken(address owner, uint256 tokens, uint256 price);
	event notifyWithdraw(address owner, uint256 tokens);
	event notifyTransfer(address owner, address recipient, uint256 tokens);




	uint public tokenIssueDeadline = now;
	uint256 public tokensIssued = 0;
	uint256 public tokensToIssue = 0;
	uint256 public tokenPrice = 1000000000000000;

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



	function createAccount () {
		accountFor(msg.sender, true);
	}


	function isMember (DaoAccount account, address allegedOwnerAddress) returns (bool) {
		if (account == DaoAccount(0x00)) return false;
		if (allegedOwnerAddress == 0x00) return false;
		if (daoAccounts[allegedOwnerAddress] == DaoAccount(0x00)) return false;

		if (daoAccounts[allegedOwnerAddress] != account) return false;
		return true;
	}

	function getTokenBalance () constant noEther returns (uint256 tokens) {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) return 0;
		return account.getTokenBalance();
	}




	function issueTokens (uint256 n, uint256 price, uint deadline) noEther onlyChallengeOwner {

		if (now < tokenIssueDeadline) throw;


		if (deadline < now) throw;


		if (n == 0) throw;

		tokenPrice = price * 1000000000000;
		tokenIssueDeadline = deadline;
		tokensToIssue = n;
		tokensIssued = 0;

		notifyTokenIssued(n, price, deadline);
	}

	function buyTokens () returns (uint256 tokens) {
		tokens = msg.value / tokenPrice;

		if (now > tokenIssueDeadline) throw;
		if (tokensIssued >= tokensToIssue) throw;



		tokensIssued += tokens;
		if (tokensIssued > tokensToIssue) throw;

	  DaoAccount account = accountFor(msg.sender, true);
		if (account.buyTokens.value(msg.value)() != tokens) throw;

		notifyBuyToken(msg.sender, tokens, msg.value);
		return tokens;
 	}

	function withdraw(uint256 tokens) noEther {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) throw;

		account.withdraw(tokens);
		notifyWithdraw(msg.sender, tokens);
	}

	function transfer(uint256 tokens, address recipient) noEther {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) throw;

		DaoAccount recipientAcc = accountFor(recipient, false);
		if (recipientAcc == DaoAccount(0x00)) throw;

		account.transfer(tokens, recipientAcc);
		notifyTransfer(msg.sender, recipient, tokens);
	}


	function terminate() noEther onlyChallengeOwner {
		notifyTerminate(this.balance);
		suicide(challengeOwner);
	}
}