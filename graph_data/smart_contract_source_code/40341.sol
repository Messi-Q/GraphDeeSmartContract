
 
contract ReentryProtectorMixin {

     
    bool reentryProtector;

    function externalEnter() internal {
        if (reentryProtector) {
            throw;
        }
        reentryProtector = true;
    }

     
     
    function externalLeave() internal {
        reentryProtector = false;
    }

}


 
contract CarefulSenderMixin {

     
    uint constant suggestedExtraGasToIncludeWithSends = 23000;

    function carefulSendWithFixedGas(address _toAddress,  uint _valueWei,  uint _extraGasIncluded ) internal returns (bool success) {
        return _toAddress.call.value(_valueWei).gas(_extraGasIncluded)();
    }

}


 
contract FundsHolderMixin is ReentryProtectorMixin, CarefulSenderMixin {

     
     
     
    mapping (address => uint) funds;

    event FundsWithdrawnEvent(
        address fromAddress,
        address toAddress,
        uint valueWei
    );

     
    function fundsOf(address _address) constant returns (uint valueWei) {
        return funds[_address];
    }

     
    function withdrawFunds() {
        externalEnter();
        withdrawFundsRP();
        externalLeave();
    }

     
     
     
    function withdrawFundsAdvanced(
        address _toAddress,
        uint _valueWei,
        uint _extraGas
    ) {
        externalEnter();
        withdrawFundsAdvancedRP(_toAddress, _valueWei, _extraGas);
        externalLeave();
    }

     
    function withdrawFundsRP() internal {
        address fromAddress = msg.sender;
        address toAddress = fromAddress;
        uint allAvailableWei = funds[fromAddress];
        withdrawFundsAdvancedRP(
            toAddress,
            allAvailableWei,
            suggestedExtraGasToIncludeWithSends
        );
    }

     
     
    function withdrawFundsAdvancedRP(address _toAddress, uint _valueWei, uint _extraGasIncluded ) internal {
        if (msg.value != 0) {   throw;   }
        address fromAddress = msg.sender;
        if (_valueWei > funds[fromAddress]) {  throw;    }
        funds[fromAddress] -= _valueWei;
        bool sentOk = carefulSendWithFixedGas(  _toAddress,   _valueWei,   _extraGasIncluded );
        if (!sentOk) { throw;   }
        FundsWithdrawnEvent(fromAddress, _toAddress, _valueWei);
    }

}


 
contract MoneyRounderMixin {

     
     
     
     
     
     
     
     
    function roundMoneyDownNicely(uint _rawValueWei) constant internal
    returns (uint nicerValueWei) {
        if (_rawValueWei < 1 finney) {
            return _rawValueWei;
        } else if (_rawValueWei < 10 finney) {
            return 10 szabo * (_rawValueWei / 10 szabo);
        } else if (_rawValueWei < 100 finney) {
            return 100 szabo * (_rawValueWei / 100 szabo);
        } else if (_rawValueWei < 1 ether) {
            return 1 finney * (_rawValueWei / 1 finney);
        } else if (_rawValueWei < 10 ether) {
            return 10 finney * (_rawValueWei / 10 finney);
        } else if (_rawValueWei < 100 ether) {
            return 100 finney * (_rawValueWei / 100 finney);
        } else if (_rawValueWei < 1000 ether) {
            return 1 ether * (_rawValueWei / 1 ether);
        } else if (_rawValueWei < 10000 ether) {
            return 10 ether * (_rawValueWei / 10 ether);
        } else {
            return _rawValueWei;
        }
    }
    
     
     
     
     
    function roundMoneyUpToWholeFinney(uint _valueWei) constant internal
    returns (uint valueFinney) {
        return (1 finney + _valueWei - 1 wei) / 1 finney;
    }

}


 
contract NameableMixin {

     

    uint constant minimumNameLength = 1;
    uint constant maximumNameLength = 25;
    string constant nameDataPrefix = "NAME:";

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function validateNameInternal(string _name) constant internal
    returns (bool allowed) {
        bytes memory nameBytes = bytes(_name);
        uint lengthBytes = nameBytes.length;
        if (lengthBytes < minimumNameLength ||
            lengthBytes > maximumNameLength) {
            return false;
        }
        bool foundNonPunctuation = false;
        for (uint i = 0; i < lengthBytes; i++) {
            byte b = nameBytes[i];
            if (
                (b >= 48 && b <= 57) ||  
                (b >= 65 && b <= 90) ||  
                (b >= 97 && b <= 122)    
            ) {
                foundNonPunctuation = true;
                continue;
            }
            if (
                b == 32 ||  
                b == 33 ||  
                b == 40 ||  
                b == 41 ||  
                b == 45 ||  
                b == 46 ||  
                b == 95     
            ) {
                continue;
            }
            return false;
        }
        return foundNonPunctuation;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function extractNameFromData(bytes _data) constant internal
    returns (string extractedName) {
         
        uint expectedPrefixLength = (bytes(nameDataPrefix)).length;
        if (_data.length < expectedPrefixLength) {
            throw;
        }
        uint i;
        for (i = 0; i < expectedPrefixLength; i++) {
            if ((bytes(nameDataPrefix))[i] != _data[i]) {
                throw;
            }
        }
         
        uint payloadLength = _data.length - expectedPrefixLength;
        if (payloadLength < minimumNameLength ||
            payloadLength > maximumNameLength) {
            throw;
        }
        string memory name = new string(payloadLength);
        for (i = 0; i < payloadLength; i++) {
            (bytes(name))[i] = _data[expectedPrefixLength + i];
        }
        return name;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function computeNameFuzzyHash(string _name) constant internal
    returns (uint fuzzyHash) {
        bytes memory nameBytes = bytes(_name);
        uint h = 0;
        uint len = nameBytes.length;
        if (len > maximumNameLength) {
            len = maximumNameLength;
        }
        for (uint i = 0; i < len; i++) {
            uint mul = 128;
            byte b = nameBytes[i];
            uint ub = uint(b);
            if (b >= 48 && b <= 57) {
                 
                h = h * mul + ub;
            } else if (b >= 65 && b <= 90) {
                 
                h = h * mul + ub;
            } else if (b >= 97 && b <= 122) {
                 
                uint upper = ub - 32;
                h = h * mul + upper;
            } else {
                 
            }
        }
        return h;
    }

}


 
contract ThroneRulesMixin {

     
    struct ThroneRules {
        uint startingClaimPriceWei;
        uint maximumClaimPriceWei;
        uint claimPriceAdjustPercent;
        uint curseIncubationDurationSeconds;
        uint commissionPerThousand;
    }

}


 
contract Kingdom is
  ReentryProtectorMixin,
  CarefulSenderMixin,
  FundsHolderMixin,
  MoneyRounderMixin,
  NameableMixin,
  ThroneRulesMixin {

     
    string public kingdomName;

     
    address public world;

     
    ThroneRules public rules;

     
    struct Monarch {
         
        address compensationAddress;
         
        string name;
         
        uint coronationTimestamp;
         
        uint claimPriceWei;
         
        uint compensationWei;
    }

     
    Monarch[] public monarchsByNumber;

     
     
    address public topWizard;

     
     
     
    address public subWizard;

     
     

    event ThroneClaimedEvent(uint monarchNumber);
    event CompensationSentEvent(address toAddress, uint valueWei);
    event CompensationFailEvent(address toAddress, uint valueWei);
    event CommissionEarnedEvent(address byAddress, uint valueWei);
    event WizardReplacedEvent(address oldWizard, address newWizard);
     

     
     
     
     
    function Kingdom(
        string _kingdomName,
        address _world,
        address _topWizard,
        address _subWizard,
        uint _startingClaimPriceWei,
        uint _maximumClaimPriceWei,
        uint _claimPriceAdjustPercent,
        uint _curseIncubationDurationSeconds,
        uint _commissionPerThousand
    ) {
        kingdomName = _kingdomName;
        world = _world;
        topWizard = _topWizard;
        subWizard = _subWizard;
        rules = ThroneRules(
            _startingClaimPriceWei,
            _maximumClaimPriceWei,
            _claimPriceAdjustPercent,
            _curseIncubationDurationSeconds,
            _commissionPerThousand
        );
         
         
        monarchsByNumber.push(
            Monarch(
                0,
                "",
                0,
                0,
                0
            )
        );
    }

    function numberOfMonarchs() constant returns (uint totalCount) {
         
        return monarchsByNumber.length - 1;
    }

     
     
    function isLivingMonarch() constant returns (bool alive) {
        if (numberOfMonarchs() == 0) {
            return false;
        }
        uint reignStartedTimestamp = latestMonarchInternal().coronationTimestamp;
        if (now < reignStartedTimestamp) {
             
             
             
            return true;
        }
        uint elapsedReignDurationSeconds = now - reignStartedTimestamp;
        if (elapsedReignDurationSeconds > rules.curseIncubationDurationSeconds) {
            return false;
        } else {
            return true;
        }
    }

     
    function currentClaimPriceWei() constant returns (uint priceInWei) {
        if (!isLivingMonarch()) {
            return rules.startingClaimPriceWei;
        } else {
            uint lastClaimPriceWei = latestMonarchInternal().claimPriceWei;
             
            uint newClaimPrice =
              (lastClaimPriceWei * (100 + rules.claimPriceAdjustPercent)) / 100;
            newClaimPrice = roundMoneyDownNicely(newClaimPrice);
            if (newClaimPrice < rules.startingClaimPriceWei) {
                newClaimPrice = rules.startingClaimPriceWei;
            }
            if (newClaimPrice > rules.maximumClaimPriceWei) {
                newClaimPrice = rules.maximumClaimPriceWei;
            }
            return newClaimPrice;
        }
    }

     
    function currentClaimPriceInFinney() constant
    returns (uint priceInFinney) {
        uint valueWei = currentClaimPriceWei();
        return roundMoneyUpToWholeFinney(valueWei);
    }

     
     
     
     
     
     
     
     
    function validateProposedMonarchName(string _monarchName) constant
    returns (bool allowed) {
        return validateNameInternal(_monarchName);
    }

     
     
     
     
     
     
     
    function latestMonarchInternal() constant internal
    returns (Monarch storage monarch) {
        return monarchsByNumber[monarchsByNumber.length - 1];
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function () {
        externalEnter();
        fallbackRP();
        externalLeave();
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function claimThrone(string _monarchName) {
        externalEnter();
        claimThroneRP(_monarchName);
        externalLeave();
    }

     
     
     
     
     
     
    function replaceWizard(address _replacement) {
        externalEnter();
        replaceWizardRP(_replacement);
        externalLeave();
    }

    function fallbackRP() internal {
        if (msg.data.length == 0) {
            claimThroneRP("Anonymous");
        } else {
            string memory _monarchName = extractNameFromData(msg.data);
            claimThroneRP(_monarchName);
        }
    }
    
    function claimThroneRP(
        string _monarchName
    ) internal {

        address _compensationAddress = msg.sender;

        if (!validateNameInternal(_monarchName)) {
            throw;
        }

        if (_compensationAddress == 0 ||
            _compensationAddress == address(this)) {
            throw;
        }

        uint paidWei = msg.value;
        uint priceWei = currentClaimPriceWei();
        if (paidWei < priceWei) {
            throw;
        }
         
         
        uint excessWei = paidWei - priceWei;
        if (excessWei > 1 finney) {
            throw;
        }
        
        uint compensationWei;
        uint commissionWei;
        if (!isLivingMonarch()) {
             
            commissionWei = paidWei;
            compensationWei = 0;
        } else {
            commissionWei = (paidWei * rules.commissionPerThousand) / 1000;
            compensationWei = paidWei - commissionWei;
        }

        if (commissionWei != 0) {
            recordCommissionEarned(commissionWei);
        }

        if (compensationWei != 0) {
            compensateLatestMonarch(compensationWei);
        }

         
         
        monarchsByNumber.push(Monarch(
            _compensationAddress,
            _monarchName,
            now,
            priceWei,
            0
        ));

        ThroneClaimedEvent(monarchsByNumber.length - 1);
    }

    function replaceWizardRP(address replacement) internal {
        if (msg.value != 0) {
            throw;
        }
        bool replacedOk = false;
        address oldWizard;
        if (msg.sender == topWizard) {
            oldWizard = topWizard;
            topWizard = replacement;
            WizardReplacedEvent(oldWizard, replacement);
            replacedOk = true;
        }
         
         
        if (msg.sender == subWizard) {
            oldWizard = subWizard;
            subWizard = replacement;
            WizardReplacedEvent(oldWizard, replacement);
            replacedOk = true;
        }
        if (!replacedOk) {
            throw;
        }
    }

     
     
    function recordCommissionEarned(uint _commissionWei) internal {
         
        uint topWizardWei = _commissionWei / 2;
        uint subWizardWei = _commissionWei - topWizardWei;
        funds[topWizard] += topWizardWei;
        CommissionEarnedEvent(topWizard, topWizardWei);
        funds[subWizard] += subWizardWei;
        CommissionEarnedEvent(subWizard, subWizardWei);
    }

     
     
    function compensateLatestMonarch(uint _compensationWei) internal {
        address compensationAddress = latestMonarchInternal().compensationAddress;
         
        latestMonarchInternal().compensationWei = _compensationWei;

        bool sentOk = carefulSendWithFixedGas(  compensationAddress, _compensationWei,suggestedExtraGasToIncludeWithSends  );
        if (sentOk) {
            CompensationSentEvent(compensationAddress, _compensationWei);
        } else {
             
            funds[compensationAddress] += _compensationWei;
            CompensationFailEvent(compensationAddress, _compensationWei);
        }
    }

}


 
 
 
 
 
 
 
contract KingdomFactory {

    function KingdomFactory() {
    }

    function () {
         
        throw;
    }

     
    function validateProposedThroneRules(
        uint _startingClaimPriceWei,
        uint _maximumClaimPriceWei,
        uint _claimPriceAdjustPercent,
        uint _curseIncubationDurationSeconds,
        uint _commissionPerThousand
    ) constant returns (bool allowed) {
         
         
         
        if (_startingClaimPriceWei < 10 finney ||
            _startingClaimPriceWei > 100 ether) {
            return false;
        }
        if (_maximumClaimPriceWei < 1 ether ||
            _maximumClaimPriceWei > 100000 ether) {
            return false;
        }
        if (_startingClaimPriceWei * 20 > _maximumClaimPriceWei) {
            return false;
        }
        if (_claimPriceAdjustPercent < 10 ||
            _claimPriceAdjustPercent > 900) {
            return false;
        }
        if (_curseIncubationDurationSeconds < 2 hours ||
            _curseIncubationDurationSeconds > 10000 days) {
            return false;
        }
        if (_commissionPerThousand < 10 ||
            _commissionPerThousand > 100) {
            return false;
        }
        return true;
    }

     
     
     
     
     
     
     
     
     
    function createKingdom(
        string _kingdomName,
        address _world,
        address _topWizard,
        address _subWizard,
        uint _startingClaimPriceWei,
        uint _maximumClaimPriceWei,
        uint _claimPriceAdjustPercent,
        uint _curseIncubationDurationSeconds,
        uint _commissionPerThousand
    ) returns (Kingdom newKingdom) {
        if (msg.value > 0) {
             
            throw;
        }
         
        if (_topWizard == 0 || _subWizard == 0) {
            throw;
        }
        if (_topWizard == _world || _subWizard == _world) {
            throw;
        }
        if (!validateProposedThroneRules(
            _startingClaimPriceWei,
            _maximumClaimPriceWei,
            _claimPriceAdjustPercent,
            _curseIncubationDurationSeconds,
            _commissionPerThousand
        )) {
            throw;
        }
        return new Kingdom(
            _kingdomName,
            _world,
            _topWizard,
            _subWizard,
            _startingClaimPriceWei,
            _maximumClaimPriceWei,
            _claimPriceAdjustPercent,
            _curseIncubationDurationSeconds,
            _commissionPerThousand
        );
    }

}


 
contract World is
  ReentryProtectorMixin,
  NameableMixin,
  MoneyRounderMixin,
  FundsHolderMixin,
  ThroneRulesMixin {

     
     
    address public topWizard;

     
     
    uint public kingdomCreationFeeWei;

    struct KingdomListing {
        uint kingdomNumber;
        string kingdomName;
        address kingdomContract;
        address kingdomCreator;
        uint creationTimestamp;
        address kingdomFactoryUsed;
    }
    
     
    KingdomListing[] public kingdomsByNumber;

     
     
     
    uint public maximumClaimPriceWei;

     
     
    KingdomFactory public kingdomFactory;

     
    mapping (uint => uint) kingdomNumbersByfuzzyHash;

     
     

    event KingdomCreatedEvent(uint kingdomNumber);
    event CreationFeeChangedEvent(uint newFeeWei);
    event FactoryChangedEvent(address newFactory);
    event WizardReplacedEvent(address oldWizard, address newWizard);
     

     
     
    function World(
        address _topWizard,
        uint _kingdomCreationFeeWei,
        KingdomFactory _kingdomFactory,
        uint _maximumClaimPriceWei
    ) {
        if (_topWizard == 0) {
            throw;
        }
        if (_maximumClaimPriceWei < 1 ether) {
            throw;
        }
        topWizard = _topWizard;
        kingdomCreationFeeWei = _kingdomCreationFeeWei;
        kingdomFactory = _kingdomFactory;
        maximumClaimPriceWei = _maximumClaimPriceWei;
         
         
        kingdomsByNumber.push(KingdomListing(0, "", 0, 0, 0, 0));
    }

    function numberOfKingdoms() constant returns (uint totalCount) {
        return kingdomsByNumber.length - 1;
    }

     
    function findKingdomCalled(string _kingdomName) constant
    returns (uint kingdomNumber) {
        uint fuzzyHash = computeNameFuzzyHash(_kingdomName);
        return kingdomNumbersByfuzzyHash[fuzzyHash];
    }

     
     
     
     
     
     
     
     
     
     
     
    function validateProposedKingdomName(string _kingdomName) constant
    returns (bool allowed) {
        return validateNameInternal(_kingdomName);
    }

     
     
    function validateProposedThroneRules(
        uint _startingClaimPriceWei,
        uint _claimPriceAdjustPercent,
        uint _curseIncubationDurationSeconds,
        uint _commissionPerThousand
    ) constant returns (bool allowed) {
        return kingdomFactory.validateProposedThroneRules(
            _startingClaimPriceWei,
            maximumClaimPriceWei,
            _claimPriceAdjustPercent,
            _curseIncubationDurationSeconds,
            _commissionPerThousand
        );
    }

     
     
    function kingdomCreationFeeInFinney() constant
    returns (uint feeInFinney) {
        return roundMoneyUpToWholeFinney(kingdomCreationFeeWei);
    }

     
     
    function () {
        throw;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createKingdom(
        string _kingdomName,
        uint _startingClaimPriceWei,
        uint _claimPriceAdjustPercent,
        uint _curseIncubationDurationSeconds,
        uint _commissionPerThousand
    ) {
        externalEnter();
        createKingdomRP(
            _kingdomName,
            _startingClaimPriceWei,
            _claimPriceAdjustPercent,
            _curseIncubationDurationSeconds,
            _commissionPerThousand
        );
        externalLeave();
    }

     
     
     
     
     
     
    function replaceWizard(address _replacement) {
        externalEnter();
        replaceWizardRP(_replacement);
        externalLeave();
    }

     
    function setKingdomCreationFeeWei(uint _kingdomCreationFeeWei) {
        externalEnter();
        setKingdomCreationFeeWeiRP(_kingdomCreationFeeWei);
        externalLeave();
    }

     
    function setMaximumClaimPriceWei(uint _maximumClaimPriceWei) {
        externalEnter();
        setMaximumClaimPriceWeiRP(_maximumClaimPriceWei);
        externalLeave();
    }

     
     
    function setKingdomFactory(KingdomFactory _kingdomFactory) {
        externalEnter();
        setKingdomFactoryRP(_kingdomFactory);
        externalLeave();
    }

    function createKingdomRP(
        string _kingdomName,
        uint _startingClaimPriceWei,
        uint _claimPriceAdjustPercent,
        uint _curseIncubationDurationSeconds,
        uint _commissionPerThousand
    ) internal {

        address subWizard = msg.sender;

        if (!validateNameInternal(_kingdomName)) {
            throw;
        }

        uint newKingdomNumber = kingdomsByNumber.length;
        checkUniqueAndRegisterNewKingdomName(
            _kingdomName,
            newKingdomNumber
        );

        uint paidWei = msg.value;
        if (paidWei < kingdomCreationFeeWei) {
            throw;
        }
         
         
        uint excessWei = paidWei - kingdomCreationFeeWei;
        if (excessWei > 1 finney) {
            throw;
        }
        funds[topWizard] += paidWei;
        
         
        Kingdom kingdomContract = kingdomFactory.createKingdom(
            _kingdomName,
            address(this),
            topWizard,
            subWizard,
            _startingClaimPriceWei,
            maximumClaimPriceWei,
            _claimPriceAdjustPercent,
            _curseIncubationDurationSeconds,
            _commissionPerThousand
        );

        kingdomsByNumber.push(KingdomListing(
            newKingdomNumber,
            _kingdomName,
            kingdomContract,
            msg.sender,
            now,
            kingdomFactory
        ));
    }

    function replaceWizardRP(address replacement) internal { 
        if (msg.sender != topWizard) {
            throw;
        }
        if (msg.value != 0) {
            throw;
        }
        address oldWizard = topWizard;
        topWizard = replacement;
        WizardReplacedEvent(oldWizard, replacement);
    }

    function setKingdomCreationFeeWeiRP(uint _kingdomCreationFeeWei) internal {
        if (msg.sender != topWizard) {
            throw;
        }
        if (msg.value != 0) {
            throw;
        }
        kingdomCreationFeeWei = _kingdomCreationFeeWei;
        CreationFeeChangedEvent(kingdomCreationFeeWei);
    }

    function setMaximumClaimPriceWeiRP(uint _maximumClaimPriceWei) internal {
        if (msg.sender != topWizard) {
            throw;
        }
        if (msg.value != 0) {
            throw;
        }
        if (_maximumClaimPriceWei < 1 ether) {
            throw;
        }
        maximumClaimPriceWei = _maximumClaimPriceWei;
    }

    function setKingdomFactoryRP(KingdomFactory _kingdomFactory) internal {
        if (msg.sender != topWizard) {
            throw;
        }
        if (msg.value != 0) {
            throw;
        }
        kingdomFactory = _kingdomFactory;
        FactoryChangedEvent(kingdomFactory);
    }

     
     
     
     
    function checkUniqueAndRegisterNewKingdomName(
        string _kingdomName,
        uint _newKingdomNumber
    ) internal {
        uint fuzzyHash = computeNameFuzzyHash(_kingdomName);
        if (kingdomNumbersByfuzzyHash[fuzzyHash] != 0) {
            throw;
        }
        kingdomNumbersByfuzzyHash[fuzzyHash] = _newKingdomNumber;
    }

}


 
contract ExposedInternalsForTesting is
  MoneyRounderMixin, NameableMixin {

    function roundMoneyDownNicelyET(uint _rawValueWei) constant
    returns (uint nicerValueWei) {
        return roundMoneyDownNicely(_rawValueWei);
    }

    function roundMoneyUpToWholeFinneyET(uint _valueWei) constant
    returns (uint valueFinney) {
        return roundMoneyUpToWholeFinney(_valueWei);
    }

    function validateNameInternalET(string _name) constant
    returns (bool allowed) {
        return validateNameInternal(_name);
    }

    function extractNameFromDataET(bytes _data) constant
    returns (string extractedName) {
        return extractNameFromData(_data);
    }
    
    function computeNameFuzzyHashET(string _name) constant
    returns (uint fuzzyHash) {
        return computeNameFuzzyHash(_name);
    }

}