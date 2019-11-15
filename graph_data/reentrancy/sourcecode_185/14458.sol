pragma solidity ^0.4.18;
 
contract SafeMath {

	function safeMul(uint256 a, uint256 b) public pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeDiv(uint256 a, uint256 b) public pure returns (uint256) {
		 
		 
		 
		 
		return  a / b;
	}

	function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
		uint256 c = a + b;
		assert(c>=a && c>=b);
		return c;
	}

}
 
contract ERC20 {

	function totalSupply() public constant returns (uint256);
	function balanceOf(address _owner) public constant returns (uint256);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256);

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ContractReceiver {
	function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract ERC223 is ERC20 {

	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success);

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract BankeraToken is ERC223, SafeMath {

	string public constant name = "Banker Token";      
	string public constant symbol = "BNK";       
	uint8 public constant decimals = 8;          
	uint256 private issued = 0;   				 
	uint256 private totalTokens = 25000000000 * 100000000;  

	address private contractOwner;
	address private rewardManager;
	address private roundManager;
	address private issueManager;
	uint64 public currentRound = 0;

	bool public paused = false;

	mapping (uint64 => Reward) public reward;	 
	mapping (address => AddressBalanceInfoStructure) public accountBalances;	 
	mapping (uint64 => uint256) public issuedTokensInRound;	 
	mapping (address => mapping (address => uint256)) internal allowed;

	uint256 public blocksPerRound;  
	uint256 public lastBlockNumberInRound;

	struct Reward {
		uint64 roundNumber;
		uint256 rewardInWei;
		uint256 rewardRate;  
		bool isConfigured;
	}

	struct AddressBalanceInfoStructure {
		uint256 addressBalance;
		mapping (uint256 => uint256) roundBalanceMap;  
		mapping (uint64 => bool) wasModifiedInRoundMap;  
		uint64[] mapKeys;	 
		uint64 claimedRewardTillRound;
		uint256 totalClaimedReward;
	}

	 
	function BankeraToken(uint256 _blocksPerRound, uint64 _round) public {
		contractOwner = msg.sender;
		lastBlockNumberInRound = block.number;

		blocksPerRound = _blocksPerRound;
		currentRound = _round;
	}

	function() public whenNotPaused payable {
	}

	 
	 
	function tokenFallback(address _from, uint256 _value, bytes _data) public whenNotPaused view {
		revert();
	}

	function setReward(uint64 _roundNumber, uint256 _roundRewardInWei) public whenNotPaused onlyRewardManager {
		isNewRound();

		Reward storage rewardInfo = reward[_roundNumber];

		 
		assert(rewardInfo.roundNumber == _roundNumber);
		assert(!rewardInfo.isConfigured);  

		rewardInfo.rewardInWei = _roundRewardInWei;
		if(_roundRewardInWei > 0){
			rewardInfo.rewardRate = safeDiv(_roundRewardInWei, issuedTokensInRound[_roundNumber]);
		}
		rewardInfo.isConfigured = true;
	}

	 
	function changeContractOwner(address _newContractOwner) public onlyContractOwner {
		isNewRound();
		if (_newContractOwner != contractOwner) {
			contractOwner = _newContractOwner;
		} else {
			revert();
		}
	}

	 
	function changeRewardManager(address _newRewardManager) public onlyContractOwner {
		isNewRound();
		if (_newRewardManager != rewardManager) {
			rewardManager = _newRewardManager;
		} else {
			revert();
		}
	}

	 
	function changeRoundManager(address _newRoundManager) public onlyContractOwner {
		isNewRound();
		if (_newRoundManager != roundManager) {
			roundManager = _newRoundManager;
		} else {
			revert();
		}
	}

	 
	function changeIssueManager(address _newIssueManager) public onlyContractOwner {
		isNewRound();
		if (_newIssueManager != issueManager) {
			issueManager = _newIssueManager;
		} else {
			revert();
		}
	}

	function setBlocksPerRound(uint64 _newBlocksPerRound) public whenNotPaused onlyRoundManager {
		blocksPerRound = _newBlocksPerRound;
	}
	 
	function pause() onlyContractOwner whenNotPaused public {
		paused = true;
	}

	 
	function resume() onlyContractOwner whenPaused public {
		paused = false;
	}
	 
	modifier onlyContractOwner() {
		if(msg.sender != contractOwner){
			revert();
		}
		_;
	}
	 
	modifier onlyRewardManager() {
		if(msg.sender != rewardManager && msg.sender != contractOwner){
			revert();
		}
		_;
	}
	 
	modifier onlyRoundManager() {
		if(msg.sender != roundManager && msg.sender != contractOwner){
			revert();
		}
		_;
	}
	 
	modifier onlyIssueManager() {
		if(msg.sender != issueManager && msg.sender != contractOwner){
			revert();
		}
		_;
	}

	modifier notSelf(address _to) {
		if(msg.sender == _to){
			revert();
		}
		_;
	}
	 
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	 
	modifier whenPaused() {
		require(paused);
		_;
	}

	function getRoundBalance(address _address, uint256 _round) public view returns (uint256) {
		return accountBalances[_address].roundBalanceMap[_round];
	}

	function isModifiedInRound(address _address, uint64 _round) public view returns (bool) {
		return accountBalances[_address].wasModifiedInRoundMap[_round];
	}

	function getBalanceModificationRounds(address _address) public view returns (uint64[]) {
		return accountBalances[_address].mapKeys;
	}

	 
	function issueTokens(address _receiver, uint256 _tokenAmount) public whenNotPaused onlyIssueManager {
		isNewRound();
		issue(_receiver, _tokenAmount);
	}

	function withdrawEther() public onlyContractOwner {
		isNewRound();
		if(this.balance > 0) {
			contractOwner.transfer(this.balance);
		} else {
			revert();
		}
	}

	 
	 
	function transfer(address _to, uint256 _value) public notSelf(_to) whenNotPaused returns (bool success){
		require(_to != address(0));
		 
		bytes memory empty;
		if(isContract(_to)) {
			return transferToContract(msg.sender, _to, _value, empty);
		}
		else {
			return transferToAddress(msg.sender, _to, _value, empty);
		}
	}

	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return accountBalances[_owner].addressBalance;
	}

	 
	function totalSupply() public constant returns (uint256){
		return totalTokens;
	}

	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		require(_to != address(0));
		require(_value <= allowed[_from][msg.sender]);

		 
		bytes memory empty;
		if(isContract(_to)) {
			require(transferToContract(_from, _to, _value, empty));
		}
		else {
			require(transferToAddress(_from, _to, _value, empty));
		}
		allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
		return true;
	}

	 
	 
	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	 
	function allowance(address _owner, address _spender) public view whenNotPaused returns (uint256) {
		return allowed[_owner][_spender];
	}

	 

	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	 
	function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused notSelf(_to) returns (bool success){
		require(_to != address(0));
		if(isContract(_to)) {
			return transferToContract(msg.sender, _to, _value, _data);
		}
		else {
			return transferToAddress(msg.sender, _to, _value, _data);
		}
	}

	 
	 
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public whenNotPaused notSelf(_to) returns (bool success){
		require(_to != address(0));
		if(isContract(_to)) {
			if(accountBalances[msg.sender].addressBalance < _value){		 
				revert();
			}
			if(safeAdd(accountBalances[_to].addressBalance, _value) < accountBalances[_to].addressBalance){		 
				revert();
			}

			isNewRound();
			subFromAddressBalancesInfo(msg.sender, _value);	 
			addToAddressBalancesInfo(_to, _value);	 

			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));

			 
			Transfer(msg.sender, _to, _value, _data);
			Transfer(msg.sender, _to, _value);
			return true;
		} else {
			return transferToAddress(msg.sender, _to, _value, _data);
		}
	}

	function claimReward() public whenNotPaused returns (uint256 rewardAmountInWei) {
		isNewRound();
		return claimRewardTillRound(currentRound);
	}

	function claimRewardTillRound(uint64 _claimTillRound) public whenNotPaused returns (uint256 rewardAmountInWei) {
		isNewRound();
		rewardAmountInWei = calculateClaimableRewardTillRound(msg.sender, _claimTillRound);
		accountBalances[msg.sender].claimedRewardTillRound = _claimTillRound;

		if (rewardAmountInWei > 0){
			accountBalances[msg.sender].totalClaimedReward = safeAdd(accountBalances[msg.sender].totalClaimedReward, rewardAmountInWei);
			msg.sender.transfer(rewardAmountInWei);
		}

		return rewardAmountInWei;
	}

	function calculateClaimableReward(address _address) public constant returns (uint256 rewardAmountInWei) {
		return calculateClaimableRewardTillRound(_address, currentRound);
	}

	function calculateClaimableRewardTillRound(address _address, uint64 _claimTillRound) public constant returns (uint256) {
		uint256 rewardAmountInWei = 0;

		if (_claimTillRound > currentRound) { revert(); }
		if (currentRound < 1) { revert(); }

		AddressBalanceInfoStructure storage accountBalanceInfo = accountBalances[_address];
		if(accountBalanceInfo.mapKeys.length == 0){	revert(); }

		uint64 userLastClaimedRewardRound = accountBalanceInfo.claimedRewardTillRound;
		if (_claimTillRound < userLastClaimedRewardRound) { revert(); }

		for (uint64 workRound = userLastClaimedRewardRound; workRound < _claimTillRound; workRound++) {

			Reward storage rewardInfo = reward[workRound];
			assert(rewardInfo.isConfigured);  

			if(accountBalanceInfo.wasModifiedInRoundMap[workRound]){
				rewardAmountInWei = safeAdd(rewardAmountInWei, safeMul(accountBalanceInfo.roundBalanceMap[workRound], rewardInfo.rewardRate));
			} else {
				uint64 lastBalanceModifiedRound = 0;
				for (uint256 i = accountBalanceInfo.mapKeys.length; i > 0; i--) {
					uint64 modificationInRound = accountBalanceInfo.mapKeys[i-1];
					if (modificationInRound <= workRound) {
						lastBalanceModifiedRound = modificationInRound;
						break;
					}
				}
				rewardAmountInWei = safeAdd(rewardAmountInWei, safeMul(accountBalanceInfo.roundBalanceMap[lastBalanceModifiedRound], rewardInfo.rewardRate));
			}
		}
		return rewardAmountInWei;
	}

	function createRounds(uint256 maxRounds) public {
		uint256 blocksAfterLastRound = safeSub(block.number, lastBlockNumberInRound);	 

		if(blocksAfterLastRound >= blocksPerRound){	 

			uint256 roundsNeedToCreate = safeDiv(blocksAfterLastRound, blocksPerRound);	 
			if(roundsNeedToCreate > maxRounds){
				roundsNeedToCreate = maxRounds;
			}
			lastBlockNumberInRound = safeAdd(lastBlockNumberInRound, safeMul(roundsNeedToCreate, blocksPerRound));
			for (uint256 i = 0; i < roundsNeedToCreate; i++) {
				updateRoundInformation();
			}
		}
	}

	 
	 
	function isContract(address _address) private view returns (bool is_contract) {
		uint256 length;
		assembly {
		 
			length := extcodesize(_address)
		}
		return (length > 0);
	}

	function isNewRound() private {
		uint256 blocksAfterLastRound = safeSub(block.number, lastBlockNumberInRound);	 
		if(blocksAfterLastRound >= blocksPerRound){	 
			updateRoundsInformation(blocksAfterLastRound);
		}
	}

	function updateRoundsInformation(uint256 _blocksAfterLastRound) private {
		uint256 roundsNeedToCreate = safeDiv(_blocksAfterLastRound, blocksPerRound);	 
		lastBlockNumberInRound = safeAdd(lastBlockNumberInRound, safeMul(roundsNeedToCreate, blocksPerRound));	 
		for (uint256 i = 0; i < roundsNeedToCreate; i++) {
			updateRoundInformation();
		}
	}

	function updateRoundInformation() private {
		issuedTokensInRound[currentRound] = issued;

		Reward storage rewardInfo = reward[currentRound];
		rewardInfo.roundNumber = currentRound;

		currentRound = currentRound + 1;
	}

	function issue(address _receiver, uint256 _tokenAmount) private {
		if(_tokenAmount == 0){
			revert();
		}
		uint256 newIssuedAmount = safeAdd(_tokenAmount, issued);
		if(newIssuedAmount > totalTokens){
			revert();
		}
		addToAddressBalancesInfo(_receiver, _tokenAmount);
		issued = newIssuedAmount;
		bytes memory empty;
		if(isContract(_receiver)) {
			ContractReceiver receiverContract = ContractReceiver(_receiver);
			receiverContract.tokenFallback(msg.sender, _tokenAmount, empty);
		}
		 
		Transfer(msg.sender, _receiver, _tokenAmount, empty);
		Transfer(msg.sender, _receiver, _tokenAmount);
	}

	function addToAddressBalancesInfo(address _receiver, uint256 _tokenAmount) private {
		AddressBalanceInfoStructure storage accountBalance = accountBalances[_receiver];

		if(!accountBalance.wasModifiedInRoundMap[currentRound]){	 
			 
			if(accountBalance.mapKeys.length == 0 && currentRound > 0){
				accountBalance.claimedRewardTillRound = currentRound;
			}
			accountBalance.mapKeys.push(currentRound);
			accountBalance.wasModifiedInRoundMap[currentRound] = true;
		}
		accountBalance.addressBalance = safeAdd(accountBalance.addressBalance, _tokenAmount);
		accountBalance.roundBalanceMap[currentRound] = accountBalance.addressBalance;
	}

	function subFromAddressBalancesInfo(address _adr, uint256 _tokenAmount) private {
		AddressBalanceInfoStructure storage accountBalance = accountBalances[_adr];
		if(!accountBalance.wasModifiedInRoundMap[currentRound]){	 
			accountBalance.mapKeys.push(currentRound);
			accountBalance.wasModifiedInRoundMap[currentRound] = true;
		}
		accountBalance.addressBalance = safeSub(accountBalance.addressBalance, _tokenAmount);
		accountBalance.roundBalanceMap[currentRound] = accountBalance.addressBalance;
	}
	 
	function transferToAddress(address _from, address _to, uint256 _value, bytes _data) private returns (bool success) {
		if(accountBalances[_from].addressBalance < _value){		 
			revert();
		}
		if(safeAdd(accountBalances[_to].addressBalance, _value) < accountBalances[_to].addressBalance){		 
			revert();
		}

		isNewRound();
		subFromAddressBalancesInfo(_from, _value);	 
		addToAddressBalancesInfo(_to, _value);	 

		 
		Transfer(_from, _to, _value, _data);
		Transfer(_from, _to, _value);
		return true;
	}

	 
	function transferToContract(address _from, address _to, uint256 _value, bytes _data) private returns (bool success) {
		if(accountBalances[_from].addressBalance < _value){		 
			revert();
		}
		if(safeAdd(accountBalances[_to].addressBalance, _value) < accountBalances[_to].addressBalance){		 
			revert();
		}

		isNewRound();
		subFromAddressBalancesInfo(_from, _value);	 
		addToAddressBalancesInfo(_to, _value);	 

		ContractReceiver receiver = ContractReceiver(_to);
		receiver.tokenFallback(_from, _value, _data);

		Transfer(_from, _to, _value, _data);
		Transfer(_from, _to, _value);
		return true;
	}
}