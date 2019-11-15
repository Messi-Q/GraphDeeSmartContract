 

 

pragma solidity ^0.4.6;

 

 

contract TokenTracker {
   
  uint public restrictedShare; 

   
  mapping(address => uint) public tokens;

   
   
  mapping(address => uint) public restrictions;
  
   
  uint public totalRestrictedTokens; 
  uint public totalUnrestrictedTokens; 
  
   
   
  uint public totalRestrictedAssignments; 
  uint public totalUnrestrictedAssignments; 

   
   
  bool public assignmentsClosed = false;
  
   
   
   
   
  uint public burnMultDen;
  uint public burnMultNom;

  function TokenTracker(uint _restrictedShare) {
     
    if (_restrictedShare >= 100) { throw; }
    
    restrictedShare = _restrictedShare;
  }
  
   
  
   
  function isUnrestricted() constant returns (bool) {
    return (assignmentsClosed && totalRestrictedTokens == 0);
  }

   
  function multFracCeiling(uint x, uint a, uint b) returns (uint) {
     
    if (a == 0) { return 0; }
    
     
     
    return (x * a + (b - 1)) / b; 
  }
    
   
  function isRegistered(address addr, bool restricted) constant returns (bool) {
    if (restricted) {
      return (restrictions[addr] > 0);
    } else {
      return (tokens[addr] > 0);
    }
  }

   
   
   
  function assign(address addr, uint tokenAmount, bool restricted) internal {
     
    if (assignmentsClosed) { throw; }

     
    tokens[addr] += tokenAmount;

     
    if (restricted) {
      totalRestrictedTokens += tokenAmount;
      totalRestrictedAssignments += 1;
      restrictions[addr] += tokenAmount;
    } else {
      totalUnrestrictedTokens += tokenAmount;
      totalUnrestrictedAssignments += 1;
    }
  }

   
  function closeAssignmentsIfOpen() internal {
     
    if (assignmentsClosed) { return; } 
    
     
    assignmentsClosed = true;

     
    uint totalTokensTarget = (totalUnrestrictedTokens * 100) / 
      (100 - restrictedShare);
    
     
    uint totalTokensExisting = totalRestrictedTokens + totalUnrestrictedTokens;
      
     
    uint totalBurn = 0; 
    if (totalTokensExisting > totalTokensTarget) {
      totalBurn = totalTokensExisting - totalTokensTarget; 
    }

     
     
    burnMultNom = totalBurn;
    burnMultDen = totalRestrictedTokens;
    
     
  }

   
  function unrestrict(address addr) internal returns (uint) {
     
    if (!assignmentsClosed) { throw; }

     
    uint restrictionsForAddr = restrictions[addr];
    
     
    if (restrictionsForAddr == 0) { throw; }

     
     
     
    uint burn = multFracCeiling(restrictionsForAddr, burnMultNom, burnMultDen);

     
    tokens[addr] -= burn;
    
     
    delete restrictions[addr];
    
     
    totalRestrictedTokens   -= restrictionsForAddr;
    totalUnrestrictedTokens += restrictionsForAddr - burn;
      
    return burn;
  }
}

 

 
 

contract Phased {
   
  uint[] public phaseEndTime;

   
  uint public N; 

   
  mapping(uint => uint) public maxDelay; 

   

   
  function getPhaseAtTime(uint time) constant returns (uint n) {
     
    if (time > now) { throw; }
    
     
    while (n < N && phaseEndTime[n] <= time) {
      n++;
    }
  }

   
  function isPhase(uint time, uint n) constant returns (bool) {
     
    if (time > now) { throw; }
    
     
    if (n >= N) { throw; }
    
     
    if (n > 0 && phaseEndTime[n-1] > time) { return false; } 
    
     
    if (n < N && time >= phaseEndTime[n]) { return false; } 
   
    return true; 
  }
  
   
  function getPhaseStartTime(uint n) constant returns (uint) {
     
    if (n == 0) { throw; }
   
    return phaseEndTime[n-1];
  }
    
   
   
   
  function addPhase(uint time) internal {
     
    if (N > 0 && time <= phaseEndTime[N-1]) { throw; } 

     
    if (time <= now) { throw; }
   
     
    phaseEndTime.push(time);
    N++;
  }
  
   
  function setMaxDelay(uint i, uint timeDelta) internal {
     
    if (i >= N) { throw; }

    maxDelay[i] = timeDelta;
  }

   
  function delayPhaseEndBy(uint n, uint timeDelta) internal {
     
    if (n >= N) { throw; }

     
    if (now >= phaseEndTime[n]) { throw; }

     
     
    if (timeDelta > maxDelay[n]) { throw; }

     
     
    maxDelay[n] -= timeDelta;

     
    for (uint i = n; i < N; i++) {
      phaseEndTime[i] += timeDelta;
    }
  }

   
  function endCurrentPhaseIn(uint timeDelta) internal {
     
    uint n = getPhaseAtTime(now);

     
    if (n >= N) { throw; }
   
     
    if (timeDelta == 0) { 
      timeDelta = 1; 
    }
    
     
     
    if (now + timeDelta < phaseEndTime[n]) { 
      phaseEndTime[n] = now + timeDelta;
    }
  }
}

 

 

contract StepFunction {
  uint public phaseLength;
  uint public nSteps;
  uint public step;

  function StepFunction(uint _phaseLength, uint _initialValue, uint _nSteps) {
     
    if (_nSteps > _phaseLength) { throw; } 
  
     
    step = _initialValue / _nSteps;
    
     
    if ( step * _nSteps != _initialValue) { throw; } 

    phaseLength = _phaseLength;
    nSteps = _nSteps; 
  }
 
   
  
   
  function getStepFunction(uint elapsedTime) constant returns (uint) {
     
    if (elapsedTime >= phaseLength) { throw; }
    
     
     
     
    uint timeLeft  = phaseLength - elapsedTime - 1; 

     
     
     
     
    uint stepsLeft = ((nSteps + 1) * timeLeft) / phaseLength; 

     
    return stepsLeft * step;
  }
}

 

 

contract Targets {

   
  mapping(uint => uint) public counter;
  
   
  mapping(uint => uint) public target;

   
  function targetReached(uint id) constant returns (bool) {
    return (counter[id] >= target[id]);
  }
  
   
  
   
  function setTarget(uint id, uint _target) internal {
    target[id] = _target;
  }
 
   
   
   
  function addTowardsTarget(uint id, uint amount) 
    internal 
    returns (bool firstReached) 
  {
    firstReached = (counter[id] < target[id]) && 
                   (counter[id] + amount >= target[id]);
    counter[id] += amount;
  }
}

 

 

contract Parameters {

   

   
  uint public constant round0StartTime      = 1484676000; 
  
   
   
  uint public constant round1StartTime      = 1495040400; 
  
   
  uint public constant round0EndTime        = round0StartTime + 6 weeks;
  uint public constant round1EndTime        = round1StartTime + 6 weeks;
  uint public constant finalizeStartTime    = round1EndTime   + 1 weeks;
  
   
  uint public constant finalizeEndTime      = finalizeStartTime + 1000 years;
  
   
   
  uint public constant maxRoundDelay     = 270 days;

   
   
  uint public constant gracePeriodAfterRound0Target  = 1 days;
  uint public constant gracePeriodAfterRound1Target  = 0 days;

   
  
   
  uint public constant tokensPerCHF = 10; 
  
   
  uint public constant minDonation = 1 ether; 
 
   
  uint public constant round0Bonus = 200; 
  
   
  uint public constant round1InitialBonus = 25;
  
   
  uint public constant round1BonusSteps = 5;
 
   
  uint public constant millionInCents = 10**6 * 100;
  uint public constant round0Target = 1 * millionInCents; 
  uint public constant round1Target = 20 * millionInCents;

   
   
  uint public constant earlyContribShare = 22; 
}

 

contract FDC is TokenTracker, Phased, StepFunction, Targets, Parameters {
   
  string public name;
  
   

   
  enum state {
    pause,          
    earlyContrib,   
    round0,         
    round1,         
    offChainReg,    
    finalization,   
                    
    done            
  }

   
  mapping(uint => state) stateOfPhase;

   
   
   
  mapping(bytes32 => bool) memoUsed;

   
  address[] public donorList;  
  address[] public earlyContribList;  
  
   
   
   
  uint public weiPerCHF;       
  
   
  uint public totalWeiDonated; 
  
   
  mapping(address => uint) public weiDonated; 

   
   
   
  address public foundationWallet; 
  
   
   
  address public registrarAuth; 
  
   
  address public exchangeRateAuth; 

   
  address public masterAuth; 

   
 
   
   
  uint phaseOfRound0;
  uint phaseOfRound1;
  
   
  event DonationReceipt (address indexed addr,           
                         string indexed currency,        
                         uint indexed bonusMultiplierApplied,  
                         uint timestamp,                 
                         uint tokenAmount,               
                         bytes32 memo);                  
  event EarlyContribReceipt (address indexed addr,       
                             uint tokenAmount,           
                             bytes32 memo);              
  event BurnReceipt (address indexed addr,               
                     uint tokenAmountBurned);            

   
  function FDC(address _masterAuth, string _name) TokenTracker(earlyContribShare) StepFunction(round1EndTime-round1StartTime, round1InitialBonus, round1BonusSteps) {
     
    name = _name;

     
    foundationWallet  = _masterAuth;
    masterAuth     = _masterAuth;
    exchangeRateAuth  = _masterAuth;
    registrarAuth  = _masterAuth;

     
    stateOfPhase[0] = state.earlyContrib; 
    addPhase(round0StartTime);      
    stateOfPhase[1] = state.round0;
    addPhase(round0EndTime);        
    stateOfPhase[2] = state.offChainReg;
    addPhase(round1StartTime);      
    stateOfPhase[3] = state.round1;
    addPhase(round1EndTime);        
    stateOfPhase[4] = state.offChainReg;
    addPhase(finalizeStartTime);    
    stateOfPhase[5] = state.finalization;
    addPhase(finalizeEndTime);      
    stateOfPhase[6] = state.done;

     
     
    phaseOfRound0 = 1;
    phaseOfRound1 = 3;
    
     
    setMaxDelay(phaseOfRound0 - 1, maxRoundDelay);
    setMaxDelay(phaseOfRound1 - 1, maxRoundDelay);

     
    setTarget(phaseOfRound0, round0Target);
    setTarget(phaseOfRound1, round1Target);
  }
  
   

   
  function getState() constant returns (state) {
     return stateOfPhase[getPhaseAtTime(now)];
  }
  
   
  function getMultiplierAtTime(uint time) constant returns (uint) {
     
    uint n = getPhaseAtTime(time);

     
    if (stateOfPhase[n] == state.round0) {
      return 100 + round0Bonus;
    }

     
    if (stateOfPhase[n] == state.round1) {
      return 100 + getStepFunction(time - getPhaseStartTime(n));
    }

     
    throw;
  }

   
  function donateAsWithChecksum(address addr, bytes4 checksum) payable returns (bool) {
     
    bytes32 hash = sha256(addr);
    
     
    if (bytes4(hash) != checksum) { throw ; }

     
    return donateAs(addr);
  }

   
  function finalize(address addr) {
     
    if (getState() != state.finalization) { throw; }

     
    closeAssignmentsIfOpen(); 

     
    uint tokensBurned = unrestrict(addr); 
    
     
    BurnReceipt(addr, tokensBurned);

     
    if (isUnrestricted()) { 
       
      endCurrentPhaseIn(0); 
    }
  }

   
  function empty() returns (bool) {
    return foundationWallet.call.value(this.balance)();
  }

   
  function getStatus(uint donationRound, address dfnAddr, address fwdAddr) public constant
    returns (
      state currentState,      
      uint fxRate,             
      uint currentMultiplier,  
      uint donationCount,      
      uint totalTokenAmount,   
      uint startTime,          
      uint endTime,            
      bool isTargetReached,    
      uint chfCentsDonated,    
      uint tokenAmount,        
      uint fwdBalance,         
      uint donated)            
  {
     
    currentState = getState();
    if (currentState == state.round0 || currentState == state.round1) {
      currentMultiplier = getMultiplierAtTime(now);
    } 
    fxRate = weiPerCHF;
    donationCount = totalUnrestrictedAssignments;
    totalTokenAmount = totalUnrestrictedTokens;
   
     
    if (donationRound == 0) {
      startTime = getPhaseStartTime(phaseOfRound0);
      endTime = getPhaseStartTime(phaseOfRound0 + 1);
      isTargetReached = targetReached(phaseOfRound0);
      chfCentsDonated = counter[phaseOfRound0];
    } else {
      startTime = getPhaseStartTime(phaseOfRound1);
      endTime = getPhaseStartTime(phaseOfRound1 + 1);
      isTargetReached = targetReached(phaseOfRound1);
      chfCentsDonated = counter[phaseOfRound1];
    }
    
     
    tokenAmount = tokens[dfnAddr];
    donated = weiDonated[dfnAddr];
    
     
    fwdBalance = fwdAddr.balance;
  }
  
   
  function setWeiPerCHF(uint weis) {
     
    if (msg.sender != exchangeRateAuth) { throw; }

     
    weiPerCHF = weis;
  }

   
  function registerEarlyContrib(address addr, uint tokenAmount, bytes32 memo) {
     
    if (msg.sender != registrarAuth) { throw; }

     
    if (getState() != state.earlyContrib) { throw; }

     
    if (!isRegistered(addr, true)) {
      earlyContribList.push(addr);
    }
    
     
    assign(addr, tokenAmount, true);
    
     
    EarlyContribReceipt(addr, tokenAmount, memo);
  }

   
  function registerOffChainDonation(address addr, uint timestamp, uint chfCents, string currency, bytes32 memo) {
     
    if (msg.sender != registrarAuth) { throw; }

     
    uint currentPhase = getPhaseAtTime(now);
    state currentState = stateOfPhase[currentPhase];
    
     
     
    if (currentState != state.round0 && currentState != state.round1 &&
        currentState != state.offChainReg) {
      throw;
    }
   
     
    if (timestamp > now) { throw; }
   
     
    uint timestampPhase = getPhaseAtTime(timestamp);
    state timestampState = stateOfPhase[timestampPhase];
   
     
     
    if ((currentState == state.round0 || currentState == state.round1) &&
        (timestampState != currentState)) { 
      throw;
    }
    
     
     
    if (currentState == state.offChainReg && timestampPhase != currentPhase-1) {
      throw;
    }

     
    if (memoUsed[memo]) {
      throw;
    }

     
    memoUsed[memo] = true;

     
    bookDonation(addr, timestamp, chfCents, currency, memo);
  }

   
  function delayDonPhase(uint donPhase, uint timedelta) {
     
    if (msg.sender != registrarAuth) { throw; }

     
     
     
    if (donPhase == 0) {
      delayPhaseEndBy(phaseOfRound0 - 1, timedelta);
    } else if (donPhase == 1) {
      delayPhaseEndBy(phaseOfRound1 - 1, timedelta);
    }
  }

   
  function setFoundationWallet(address newAddr) {
     
    if (msg.sender != masterAuth) { throw; }
    
     
    if (getPhaseAtTime(now) >= phaseOfRound0) { throw; }
 
    foundationWallet = newAddr;
  }

   
  function setExchangeRateAuth(address newAuth) {
     
    if (msg.sender != masterAuth) { throw; }
 
    exchangeRateAuth = newAuth;
  }

   
  function setRegistrarAuth(address newAuth) {
     
    if (msg.sender != masterAuth) { throw; }
 
    registrarAuth = newAuth;
  }

   
  function setMasterAuth(address newAuth) {
     
    if (msg.sender != masterAuth) { throw; }
 
    masterAuth = newAuth;
  }

   
  
   
  function donateAs(address addr) private returns (bool) {
     
    state st = getState();
    
     
    if (st != state.round0 && st != state.round1) { throw; }

     
    if (msg.value < minDonation) { throw; }

     
    if (weiPerCHF == 0) { throw; } 

     
    totalWeiDonated += msg.value;
    weiDonated[addr] += msg.value;

     
    uint chfCents = (msg.value * 100) / weiPerCHF;
    
     
    bookDonation(addr, now, chfCents, "ETH", "");

     
    return foundationWallet.call.value(this.balance)();
  }

   
  function bookDonation(address addr, uint timestamp, uint chfCents, string currency, bytes32 memo) private {
     
    uint phase = getPhaseAtTime(timestamp);
    
     
    bool targetReached = addTowardsTarget(phase, chfCents);
    
     
    if (targetReached && phase == getPhaseAtTime(now)) {
      if (phase == phaseOfRound0) {
        endCurrentPhaseIn(gracePeriodAfterRound0Target);
      } else if (phase == phaseOfRound1) {
        endCurrentPhaseIn(gracePeriodAfterRound1Target);
      }
    }

     
    uint bonusMultiplier = getMultiplierAtTime(timestamp);
    
     
    chfCents = (chfCents * bonusMultiplier) / 100;

     
    uint tokenAmount = (chfCents * tokensPerCHF) / 100;

     
    if (!isRegistered(addr, false)) {
      donorList.push(addr);
    }
    
     
    assign(addr,tokenAmount,false);

     
    DonationReceipt(addr, currency, bonusMultiplier, timestamp, tokenAmount, 
                    memo);
  }
}