pragma solidity ^0.4.24;


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
contract TokenController {
    function proxyPayment(address _owner) public payable returns(bool);

    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 
 
 
contract Pinakion is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  

    struct  Checkpoint {

        uint128 fromBlock;

        uint128 value;
    }

    Pinakion public parentToken;

    uint public parentSnapShotBlock;

    uint public creationBlock;

    mapping (address => Checkpoint[]) balances;

    mapping (address => mapping (address => uint256)) allowed;

    Checkpoint[] totalSupplyHistory;

    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

  function Pinakion(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = Pinakion(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               Transfer(_from, _to, _amount);     
               return;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        Pinakion cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        Pinakion token = Pinakion(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (Pinakion) {
        Pinakion newToken = new Pinakion(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

contract RNG{

     
    function contribute(uint _block) public payable;

     
    function requestRN(uint _block) public payable {
        contribute(_block);
    }

     
    function getRN(uint _block) public returns (uint RN);

     
    function getUncorrelatedRN(uint _block) public returns (uint RN) {
        uint baseRN=getRN(_block);
        if (baseRN==0)
            return 0;
        else
            return uint(keccak256(msg.sender,baseRN));
    }

 }

 
contract BlockHashRNG is RNG {

    mapping (uint => uint) public randomNumber;  
    mapping (uint => uint) public reward;  



     
    function contribute(uint _block) public payable { reward[_block]+=msg.value; }


     
    function getRN(uint _block) public returns (uint RN) {
        RN=randomNumber[_block];
        if (RN==0){
            saveRN(_block);
            return randomNumber[_block];
        }
        else
            return RN;
    }

     
    function saveRN(uint _block) public {
        if (blockhash(_block) != 0x0)
            randomNumber[_block] = uint(blockhash(_block));
        if (randomNumber[_block] != 0) {  
            uint rewardToSend = reward[_block];
            reward[_block] = 0;
            msg.sender.send(rewardToSend);  
        }
    }

}


 
contract BlockHashRNGFallback is BlockHashRNG {
    
     
    function saveRN(uint _block) public {
        if (_block<block.number && randomNumber[_block]==0) { 
            if (blockhash(_block)!=0x0)  
                randomNumber[_block]=uint(blockhash(_block));
            else  
                randomNumber[_block]=uint(blockhash(block.number-1));
        }
        if (randomNumber[_block] != 0) {  
            uint rewardToSend=reward[_block];
            reward[_block]=0;
            msg.sender.send(rewardToSend);  
        }
    }
    
}

 
contract Arbitrable{
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData;  

    modifier onlyArbitrator {require(msg.sender==address(arbitrator)); _;}

     
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

     
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

     
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID);

     
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _disputeID, address _party, string _evidence);

     
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

     
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


     
    function executeRuling(uint _disputeID, uint _ruling) internal;
}

 
contract Arbitrator{

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {require(msg.value>=arbitrationCost(_extraData)); _;}
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {require(msg.value>=appealCost(_disputeID, _extraData)); _;}

     
    event AppealPossible(uint _disputeID);

     
    event DisputeCreation(uint indexed _disputeID, Arbitrable _arbitrable);

     
    event AppealDecision(uint indexed _disputeID, Arbitrable _arbitrable);

     
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID)  {}

     
    function arbitrationCost(bytes _extraData) public constant returns(uint fee);

     
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

     
    function appealCost(uint _disputeID, bytes _extraData) public constant returns(uint fee);

     
    function disputeStatus(uint _disputeID) public constant returns(DisputeStatus status);

     
    function currentRuling(uint _disputeID) public constant returns(uint ruling);

}



contract Kleros is Arbitrator, ApproveAndCallFallBack {

     
     
     

     
    Pinakion public pinakion;
    uint public constant NON_PAYABLE_AMOUNT = (2**256 - 2) / 2;  

     
     
    RNG public rng;  
    uint public arbitrationFeePerJuror = 0.05 ether;  
    uint16 public defaultNumberJuror = 3;  
    uint public minActivatedToken = 0.1 * 1e18;  
    uint[5] public timePerPeriod;  
    uint public alpha = 2000;  
    uint constant ALPHA_DIVISOR = 1e4;  
    uint public maxAppeals = 5;  
     
     
    address public governor;  

     
    uint public session = 1;       
    uint public lastPeriodChange;  
    uint public segmentSize;       
    uint public rnBlock;           
    uint public randomNumber;      

    enum Period {
        Activation,  
        Draw,        
        Vote,        
        Appeal,      
        Execution    
    }

    Period public period;

    struct Juror {
        uint balance;       
        uint atStake;       
        uint lastSession;   
        uint segmentStart;  
        uint segmentEnd;    
    }

    mapping (address => Juror) public jurors;

    struct Vote {
        address account;  
        uint ruling;      
    }

    struct VoteCounter {
        uint winningChoice;  
        uint winningCount;   
        mapping (uint => uint) voteCount;  
    }

    enum DisputeState {
        Open,        
        Resolving,   
        Executable,  
        Executed     
    }

    struct Dispute {
        Arbitrable arbitrated;        
        uint session;                 
        uint appeals;                 
        uint choices;                 
        uint16 initialNumberJurors;   
        uint arbitrationFeePerJuror;  
        DisputeState state;           
        Vote[][] votes;               
        VoteCounter[] voteCounter;    
        mapping (address => uint) lastSessionVote;  
        uint currentAppealToRepartition;  
        AppealsRepartitioned[] appealsRepartitioned;  
    }

    enum RepartitionStage {  
        Incoherent,
        Coherent,
        AtStake,
        Complete
    }

    struct AppealsRepartitioned {
        uint totalToRedistribute;    
        uint nbCoherent;             
        uint currentIncoherentVote;  
        uint currentCoherentVote;    
        uint currentAtStakeVote;     
        RepartitionStage stage;      
    }

    Dispute[] public disputes;

     
     
     

     
    event NewPeriod(Period _period, uint indexed _session);

     
    event TokenShift(address indexed _account, uint _disputeID, int _amount);

     
    event ArbitrationReward(address indexed _account, uint _disputeID, uint _amount);

     
     
     
    modifier onlyBy(address _account) {require(msg.sender == _account); _;}
    modifier onlyDuring(Period _period) {require(period == _period); _;}
    modifier onlyGovernor() {require(msg.sender == governor); _;}


     
    constructor(Pinakion _pinakion, RNG _rng, uint[5] _timePerPeriod, address _governor) public {
        pinakion = _pinakion;
        rng = _rng;
        lastPeriodChange = now;
        timePerPeriod = _timePerPeriod;
        governor = _governor;
    }

     
     
     
     

     
    function receiveApproval(address _from, uint _amount, address, bytes) public onlyBy(pinakion) {
        require(pinakion.transferFrom(_from, this, _amount));

        jurors[_from].balance += _amount;
    }

     
    function withdraw(uint _value) public {
        Juror storage juror = jurors[msg.sender];
        require(juror.atStake <= juror.balance);  
        require(_value <= juror.balance-juror.atStake);
        require(juror.lastSession != session);

        juror.balance -= _value;
        require(pinakion.transfer(msg.sender,_value));
    }

     
     
     
     

     
    function passPeriod() public {
        require(now-lastPeriodChange >= timePerPeriod[uint8(period)]);

        if (period == Period.Activation) {
            rnBlock = block.number + 1;
            rng.requestRN(rnBlock);
            period = Period.Draw;
        } else if (period == Period.Draw) {
            randomNumber = rng.getUncorrelatedRN(rnBlock);
            require(randomNumber != 0);
            period = Period.Vote;
        } else if (period == Period.Vote) {
            period = Period.Appeal;
        } else if (period == Period.Appeal) {
            period = Period.Execution;
        } else if (period == Period.Execution) {
            period = Period.Activation;
            ++session;
            segmentSize = 0;
            rnBlock = 0;
            randomNumber = 0;
        }


        lastPeriodChange = now;
        NewPeriod(period, session);
    }


     
    function activateTokens(uint _value) public onlyDuring(Period.Activation) {
        Juror storage juror = jurors[msg.sender];
        require(_value <= juror.balance);
        require(_value >= minActivatedToken);
        require(juror.lastSession != session);  

        juror.lastSession = session;
        juror.segmentStart = segmentSize;
        segmentSize += _value;
        juror.segmentEnd = segmentSize;

    }

     
    function voteRuling(uint _disputeID, uint _ruling, uint[] _draws) public onlyDuring(Period.Vote) {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage juror = jurors[msg.sender];
        VoteCounter storage voteCounter = dispute.voteCounter[dispute.appeals];
        require(dispute.lastSessionVote[msg.sender] != session);  
        require(_ruling <= dispute.choices);
         
        require(validDraws(msg.sender, _disputeID, _draws));

        dispute.lastSessionVote[msg.sender] = session;
        voteCounter.voteCount[_ruling] += _draws.length;
        if (voteCounter.winningCount < voteCounter.voteCount[_ruling]) {
            voteCounter.winningCount = voteCounter.voteCount[_ruling];
            voteCounter.winningChoice = _ruling;
        } else if (voteCounter.winningCount==voteCounter.voteCount[_ruling] && _draws.length!=0) {  
            voteCounter.winningChoice = 0;  
        }
        for (uint i = 0; i < _draws.length; ++i) {
            dispute.votes[dispute.appeals].push(Vote({
                account: msg.sender,
                ruling: _ruling
            }));
        }

        juror.atStake += _draws.length * getStakePerDraw();
        uint feeToPay = _draws.length * dispute.arbitrationFeePerJuror;
        msg.sender.transfer(feeToPay);
        ArbitrationReward(msg.sender, _disputeID, feeToPay);
    }

     
    function penalizeInactiveJuror(address _jurorAddress, uint _disputeID, uint[] _draws) public {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage inactiveJuror = jurors[_jurorAddress];
        require(period > Period.Vote);
        require(dispute.lastSessionVote[_jurorAddress] != session);  
        dispute.lastSessionVote[_jurorAddress] = session;  
        require(validDraws(_jurorAddress, _disputeID, _draws));
        uint penality = _draws.length * minActivatedToken * 2 * alpha / ALPHA_DIVISOR;
        penality = (penality < inactiveJuror.balance) ? penality : inactiveJuror.balance;  
        inactiveJuror.balance -= penality;
        TokenShift(_jurorAddress, _disputeID, -int(penality));
        jurors[msg.sender].balance += penality / 2;  
        TokenShift(msg.sender, _disputeID, int(penality / 2));
        jurors[governor].balance += penality / 2;  
        TokenShift(governor, _disputeID, int(penality / 2));
        msg.sender.transfer(_draws.length*dispute.arbitrationFeePerJuror);  
    }

     
    function oneShotTokenRepartition(uint _disputeID) public onlyDuring(Period.Execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.state == DisputeState.Open);
        require(dispute.session+dispute.appeals <= session);

        uint winningChoice = dispute.voteCounter[dispute.appeals].winningChoice;
        uint amountShift = getStakePerDraw();
        for (uint i = 0; i <= dispute.appeals; ++i) {
             
             
             
            if (winningChoice!=0 || (dispute.voteCounter[dispute.appeals].voteCount[0] == dispute.voteCounter[dispute.appeals].winningCount)) {
                uint totalToRedistribute = 0;
                uint nbCoherent = 0;
                 
                for (uint j = 0; j < dispute.votes[i].length; ++j) {
                    Vote storage vote = dispute.votes[i][j];
                    if (vote.ruling != winningChoice) {
                        Juror storage juror = jurors[vote.account];
                        uint penalty = amountShift<juror.balance ? amountShift : juror.balance;
                        juror.balance -= penalty;
                        TokenShift(vote.account, _disputeID, int(-penalty));
                        totalToRedistribute += penalty;
                    } else {
                        ++nbCoherent;
                    }
                }
                if (nbCoherent == 0) {  
                    jurors[governor].balance += totalToRedistribute;
                    TokenShift(governor, _disputeID, int(totalToRedistribute));
                } else {  
                    uint toRedistribute = totalToRedistribute / nbCoherent;  
                     
                    for (j = 0; j < dispute.votes[i].length; ++j) {
                        vote = dispute.votes[i][j];
                        if (vote.ruling == winningChoice) {
                            juror = jurors[vote.account];
                            juror.balance += toRedistribute;
                            TokenShift(vote.account, _disputeID, int(toRedistribute));
                        }
                    }
                }
            }
             
            for (j = 0; j < dispute.votes[i].length; ++j) {
                vote = dispute.votes[i][j];
                juror = jurors[vote.account];
                juror.atStake -= amountShift;  
            }
        }
        dispute.state = DisputeState.Executable;  
    }

     
    function multipleShotTokenRepartition(uint _disputeID, uint _maxIterations) public onlyDuring(Period.Execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.state <= DisputeState.Resolving);
        require(dispute.session+dispute.appeals <= session);
        dispute.state = DisputeState.Resolving;  

        uint winningChoice = dispute.voteCounter[dispute.appeals].winningChoice;
        uint amountShift = getStakePerDraw();
        uint currentIterations = 0;  
        for (uint i = dispute.currentAppealToRepartition; i <= dispute.appeals; ++i) {
             
            if (dispute.appealsRepartitioned.length < i+1) {
                dispute.appealsRepartitioned.length++;
            }

             
            if (winningChoice==0 && (dispute.voteCounter[dispute.appeals].voteCount[0] != dispute.voteCounter[dispute.appeals].winningCount)) {
                 
                dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
            }

             
            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Incoherent) {
                for (uint j = dispute.appealsRepartitioned[i].currentIncoherentVote; j < dispute.votes[i].length; ++j) {
                    if (currentIterations >= _maxIterations) {
                        return;
                    }
                    Vote storage vote = dispute.votes[i][j];
                    if (vote.ruling != winningChoice) {
                        Juror storage juror = jurors[vote.account];
                        uint penalty = amountShift<juror.balance ? amountShift : juror.balance;
                        juror.balance -= penalty;
                        TokenShift(vote.account, _disputeID, int(-penalty));
                        dispute.appealsRepartitioned[i].totalToRedistribute += penalty;
                    } else {
                        ++dispute.appealsRepartitioned[i].nbCoherent;
                    }

                    ++dispute.appealsRepartitioned[i].currentIncoherentVote;
                    ++currentIterations;
                }

                dispute.appealsRepartitioned[i].stage = RepartitionStage.Coherent;
            }

             
            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Coherent) {
                if (dispute.appealsRepartitioned[i].nbCoherent == 0) {  
                    jurors[governor].balance += dispute.appealsRepartitioned[i].totalToRedistribute;
                    TokenShift(governor, _disputeID, int(dispute.appealsRepartitioned[i].totalToRedistribute));
                    dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
                } else {  
                    uint toRedistribute = dispute.appealsRepartitioned[i].totalToRedistribute / dispute.appealsRepartitioned[i].nbCoherent;  
                     
                    for (j = dispute.appealsRepartitioned[i].currentCoherentVote; j < dispute.votes[i].length; ++j) {
                        if (currentIterations >= _maxIterations) {
                            return;
                        }
                        vote = dispute.votes[i][j];
                        if (vote.ruling == winningChoice) {
                            juror = jurors[vote.account];
                            juror.balance += toRedistribute;
                            TokenShift(vote.account, _disputeID, int(toRedistribute));
                        }

                        ++currentIterations;
                        ++dispute.appealsRepartitioned[i].currentCoherentVote;
                    }

                    dispute.appealsRepartitioned[i].stage = RepartitionStage.AtStake;
                }
            }

            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.AtStake) {
                 
                for (j = dispute.appealsRepartitioned[i].currentAtStakeVote; j < dispute.votes[i].length; ++j) {
                    if (currentIterations >= _maxIterations) {
                        return;
                    }
                    vote = dispute.votes[i][j];
                    juror = jurors[vote.account];
                    juror.atStake -= amountShift;  

                    ++currentIterations;
                    ++dispute.appealsRepartitioned[i].currentAtStakeVote;
                }

                dispute.appealsRepartitioned[i].stage = RepartitionStage.Complete;
            }

            if (dispute.appealsRepartitioned[i].stage == RepartitionStage.Complete) {
                ++dispute.currentAppealToRepartition;
            }
        }

        dispute.state = DisputeState.Executable;
    }

     
     
     
     

     
    function amountJurors(uint _disputeID) public view returns (uint nbJurors) {
        Dispute storage dispute = disputes[_disputeID];
        return (dispute.initialNumberJurors + 1) * 2**dispute.appeals - 1;
    }

     
    function validDraws(address _jurorAddress, uint _disputeID, uint[] _draws) public view returns (bool valid) {
        uint draw = 0;
        Juror storage juror = jurors[_jurorAddress];
        Dispute storage dispute = disputes[_disputeID];
        uint nbJurors = amountJurors(_disputeID);

        if (juror.lastSession != session) return false;  
        if (dispute.session+dispute.appeals != session) return false;  
        if (period <= Period.Draw) return false;  
        for (uint i = 0; i < _draws.length; ++i) {
            if (_draws[i] <= draw) return false;  
            draw = _draws[i];
            if (draw > nbJurors) return false;
            uint position = uint(keccak256(randomNumber, _disputeID, draw)) % segmentSize;  
            require(position >= juror.segmentStart);
            require(position < juror.segmentEnd);
        }

        return true;
    }

     
     
     
     

     
    function createDispute(uint _choices, bytes _extraData) public payable returns (uint disputeID) {
        uint16 nbJurors = extraDataToNbJurors(_extraData);
        require(msg.value >= arbitrationCost(_extraData));

        disputeID = disputes.length++;
        Dispute storage dispute = disputes[disputeID];
        dispute.arbitrated = Arbitrable(msg.sender);
        if (period < Period.Draw)  
            dispute.session = session;
        else  
            dispute.session = session+1;
        dispute.choices = _choices;
        dispute.initialNumberJurors = nbJurors;
        dispute.arbitrationFeePerJuror = arbitrationFeePerJuror;  
        dispute.votes.length++;
        dispute.voteCounter.length++;

        DisputeCreation(disputeID, Arbitrable(msg.sender));
        return disputeID;
    }

     
    function appeal(uint _disputeID, bytes _extraData) public payable onlyDuring(Period.Appeal) {
        super.appeal(_disputeID,_extraData);
        Dispute storage dispute = disputes[_disputeID];
        require(msg.value >= appealCost(_disputeID, _extraData));
        require(dispute.session+dispute.appeals == session);  
        require(dispute.arbitrated == msg.sender);
        
        dispute.appeals++;
        dispute.votes.length++;
        dispute.voteCounter.length++;
    }

     
    function executeRuling(uint disputeID) public {
        Dispute storage dispute = disputes[disputeID];
        require(dispute.state == DisputeState.Executable);

        dispute.state = DisputeState.Executed;
        dispute.arbitrated.rule(disputeID, dispute.voteCounter[dispute.appeals].winningChoice);
    }

     
     
     
     

     
    function arbitrationCost(bytes _extraData) public view returns (uint fee) {
        return extraDataToNbJurors(_extraData) * arbitrationFeePerJuror;
    }

     
    function appealCost(uint _disputeID, bytes _extraData) public view returns (uint fee) {
        Dispute storage dispute = disputes[_disputeID];

        if(dispute.appeals >= maxAppeals) return NON_PAYABLE_AMOUNT;

        return (2*amountJurors(_disputeID) + 1) * dispute.arbitrationFeePerJuror;
    }

     
    function extraDataToNbJurors(bytes _extraData) internal view returns (uint16 nbJurors) {
        if (_extraData.length < 2)
            return defaultNumberJuror;
        else
            return (uint16(_extraData[0]) << 8) + uint16(_extraData[1]);
    }

     
    function getStakePerDraw() public view returns (uint minActivatedTokenInAlpha) {
        return (alpha * minActivatedToken) / ALPHA_DIVISOR;
    }


     
     
     

     
    function getVoteAccount(uint _disputeID, uint _appeals, uint _voteID) public view returns (address account) {
        return disputes[_disputeID].votes[_appeals][_voteID].account;
    }

     
    function getVoteRuling(uint _disputeID, uint _appeals, uint _voteID) public view returns (uint ruling) {
        return disputes[_disputeID].votes[_appeals][_voteID].ruling;
    }

     
    function getWinningChoice(uint _disputeID, uint _appeals) public view returns (uint winningChoice) {
        return disputes[_disputeID].voteCounter[_appeals].winningChoice;
    }

     
    function getWinningCount(uint _disputeID, uint _appeals) public view returns (uint winningCount) {
        return disputes[_disputeID].voteCounter[_appeals].winningCount;
    }

     
    function getVoteCount(uint _disputeID, uint _appeals, uint _choice) public view returns (uint voteCount) {
        return disputes[_disputeID].voteCounter[_appeals].voteCount[_choice];
    }

     
    function getLastSessionVote(uint _disputeID, address _juror) public view returns (uint lastSessionVote) {
        return disputes[_disputeID].lastSessionVote[_juror];
    }

     
    function isDrawn(uint _disputeID, address _juror, uint _draw) public view returns (bool drawn) {
        Dispute storage dispute = disputes[_disputeID];
        Juror storage juror = jurors[_juror];
        if (juror.lastSession != session
        || (dispute.session+dispute.appeals != session)
        || period<=Period.Draw
        || _draw>amountJurors(_disputeID)
        || _draw==0
        || segmentSize==0
        ) {
            return false;
        } else {
            uint position = uint(keccak256(randomNumber,_disputeID,_draw)) % segmentSize;
            return (position >= juror.segmentStart) && (position < juror.segmentEnd);
        }

    }

     
    function currentRuling(uint _disputeID) public view returns (uint ruling) {
        Dispute storage dispute = disputes[_disputeID];
        return dispute.voteCounter[dispute.appeals].winningChoice;
    }

     
    function disputeStatus(uint _disputeID) public view returns (DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.session+dispute.appeals < session)  
            return DisputeStatus.Solved;
        else if(dispute.session+dispute.appeals == session) {  
            if (dispute.state == DisputeState.Open) {
                if (period < Period.Appeal)
                    return DisputeStatus.Waiting;
                else if (period == Period.Appeal)
                    return DisputeStatus.Appealable;
                else return DisputeStatus.Solved;
            } else return DisputeStatus.Solved;
        } else return DisputeStatus.Waiting;  
    }


    function executeOrder(bytes32 _data, uint _value, address _target) public onlyGovernor {
        _target.call.value(_value)(_data);
    }

     
    function setRng(RNG _rng) public onlyGovernor {
        rng = _rng;
    }

     
    function setArbitrationFeePerJuror(uint _arbitrationFeePerJuror) public onlyGovernor {
        arbitrationFeePerJuror = _arbitrationFeePerJuror;
    }

     
    function setDefaultNumberJuror(uint16 _defaultNumberJuror) public onlyGovernor {
        defaultNumberJuror = _defaultNumberJuror;
    }

     
    function setMinActivatedToken(uint _minActivatedToken) public onlyGovernor {
        minActivatedToken = _minActivatedToken;
    }

     
    function setTimePerPeriod(uint[5] _timePerPeriod) public onlyGovernor {
        timePerPeriod = _timePerPeriod;
    }

     
    function setAlpha(uint _alpha) public onlyGovernor {
        alpha = _alpha;
    }

     
    function setMaxAppeals(uint _maxAppeals) public onlyGovernor {
        maxAppeals = _maxAppeals;
    }

     
    function setGovernor(address _governor) public onlyGovernor {
        governor = _governor;
    }
}