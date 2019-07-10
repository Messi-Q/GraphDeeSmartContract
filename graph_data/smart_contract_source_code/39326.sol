pragma solidity ^0.4.4;

 
contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

 
contract Destroyable {
    address public hammer;

     
    function setHammer(address _hammer) onlyHammer
    { hammer = _hammer; }

     
    function destroy() onlyHammer
    { suicide(msg.sender); }

     
    modifier onlyHammer { if (msg.sender != hammer) throw; _; }
}

 
contract Object is Owned, Destroyable {
    function Object() {
        owner  = msg.sender;
        hammer = msg.sender;
    }
}

 
 
contract ERC20 
{
 
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Recipient {
     
    event ReceivedEther(address indexed sender,
                        uint256 indexed amount);

     
    event ReceivedTokens(address indexed from,
                         uint256 indexed value,
                         address indexed token,
                         bytes extraData);

     
    function receiveApproval(address _from, uint256 _value,
                             ERC20 _token, bytes _extraData) {
        if (!_token.transferFrom(_from, this, _value)) throw;
        ReceivedTokens(_from, _value, _token, _extraData);
    }

     
    function () payable
    { ReceivedEther(msg.sender, msg.value); }
}

 
contract Congress is Object, Recipient {
     
    uint256 public minimumQuorum;

     
    uint256 public debatingPeriodInMinutes;

     
    int256 public majorityMargin;

     
    Proposal[] public proposals;

     
    function numProposals() constant returns (uint256)
    { return proposals.length; }

     
    Member[] public members;

     
    mapping(address => uint256) public memberId;

     
    event ProposalAdded(uint256 indexed proposal,
                        address indexed recipient,
                        uint256 indexed amount,
                        string description);

     
    event Voted(uint256 indexed proposal,
                bool    indexed position,
                address indexed voter,
                string justification);

     
    event ProposalTallied(uint256 indexed proposal,
                          uint256 indexed quorum,
                          bool    indexed active);

     
    event MembershipChanged(address indexed member,
                            bool    indexed isMember);

     
    event ChangeOfRules(uint256 indexed minimumQuorum,
                        uint256 indexed debatingPeriodInMinutes,
                        int256  indexed majorityMargin);

    struct Proposal {
        address recipient;
        uint256 amount;
        string  description;
        uint256 votingDeadline;
        bool    executed;
        bool    proposalPassed;
        uint256 numberOfVotes;
        int256  currentResult;
        bytes32 proposalHash;
        Vote[]  votes;
        mapping(address => bool) voted;
    }

    struct Member {
        address member;
        string  name;
        uint256 memberSince;
    }

    struct Vote {
        bool    inSupport;
        address voter;
        string  justification;
    }

     
    modifier onlyMembers {
        if (memberId[msg.sender] == 0) throw;
        _;
    }

     
    function Congress(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate,
        int256  marginOfVotesForMajority,
        address congressLeader
    ) {
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
         
        addMember(0, '');  
        if (congressLeader != 0)
            addMember(congressLeader, 'The Founder');
    }

     
    function addMember(address targetMember, string memberName) onlyOwner {
        if (memberId[targetMember] != 0) throw;

        memberId[targetMember] = members.length;
        members.push(Member({member:      targetMember,
                             memberSince: now,
                             name:        memberName}));

        MembershipChanged(targetMember, true);
    }

     
    function removeMember(address targetMember) onlyOwner {
        if (memberId[targetMember] == 0) throw;

        uint256 targetId = memberId[targetMember];
        uint256 lastId   = members.length - 1;

         
        Member memory moved    = members[lastId];
        members[targetId]      = moved; 
        memberId[moved.member] = targetId;

         
        memberId[targetMember] = 0;
        delete members[lastId];
        --members.length;

        MembershipChanged(targetMember, false);
    }

     
    function changeVotingRules(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate,
        int256  marginOfVotesForMajority
    )
        onlyOwner
    {
        minimumQuorum           = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin          = marginOfVotesForMajority;

        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

     
    function newProposal(
        address beneficiary,
        uint256 amount,
        string  jobDescription,
        bytes   transactionBytecode
    )
        onlyMembers
        returns (uint256 id)
    {
        id               = proposals.length++;
        Proposal p       = proposals[id];
        p.recipient      = beneficiary;
        p.amount         = amount;
        p.description    = jobDescription;
        p.proposalHash   = sha3(beneficiary, amount, transactionBytecode);
        p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
        p.executed       = false;
        p.proposalPassed = false;
        p.numberOfVotes  = 0;
        ProposalAdded(id, beneficiary, amount, jobDescription);
    }

     
    function checkProposalCode(
        uint256 id,
        address beneficiary,
        uint256 amount,
        bytes   transactionBytecode
    )
        constant
        returns (bool codeChecksOut)
    {
        return proposals[id].proposalHash
            == sha3(beneficiary, amount, transactionBytecode);
    }

     
    function vote(
        uint256 id,
        bool    supportsProposal,
        string  justificationText
    )
        onlyMembers
        returns (uint256 vote)
    {
        Proposal p = proposals[id];              
        if (p.voted[msg.sender] == true) throw;  
        p.voted[msg.sender] = true;              
        p.numberOfVotes++;                       
        if (supportsProposal) {                  
            p.currentResult++;                   
        } else {                                 
            p.currentResult--;                   
        }
         
        Voted(id,  supportsProposal, msg.sender, justificationText);
    }

     
    function executeProposal( uint256 id, bytes   transactionBytecode) onlyMembers {
        Proposal p = proposals[id];

        if (now < p.votingDeadline || p.executed || p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode) || p.numberOfVotes < minimumQuorum)  throw;
         
        if (p.currentResult > majorityMargin) {
            p.executed = true;
            if (!p.recipient.call.value(p.amount)(transactionBytecode))  throw;

            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
         
        ProposalTallied(id, p.numberOfVotes, p.proposalPassed);
    }
}

library CreatorCongress {
    function create(uint256 minimumQuorumForProposals, uint256 minutesForDebate, int256 marginOfVotesForMajority, address congressLeader) returns (Congress)
    { return new Congress(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority, congressLeader); }

    function version() constant returns (string)
    { return "v0.6.3"; }

    function abi() constant returns (string)
    { return '[{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"proposals","outputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"},{"name":"description","type":"string"},{"name":"votingDeadline","type":"uint256"},{"name":"executed","type":"bool"},{"name":"proposalPassed","type":"bool"},{"name":"numberOfVotes","type":"uint256"},{"name":"currentResult","type":"int256"},{"name":"proposalHash","type":"bytes32"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"targetMember","type":"address"}],"name":"removeMember","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"id","type":"uint256"},{"name":"transactionBytecode","type":"bytes"}],"name":"executeProposal","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"memberId","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"numProposals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hammer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"members","outputs":[{"name":"member","type":"address"},{"name":"name","type":"string"},{"name":"memberSince","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"debatingPeriodInMinutes","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"minimumQuorum","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"destroy","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"},{"name":"_token","type":"address"},{"name":"_extraData","type":"bytes"}],"name":"receiveApproval","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"majorityMargin","outputs":[{"name":"","type":"int256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"jobDescription","type":"string"},{"name":"transactionBytecode","type":"bytes"}],"name":"newProposal","outputs":[{"name":"id","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"minimumQuorumForProposals","type":"uint256"},{"name":"minutesForDebate","type":"uint256"},{"name":"marginOfVotesForMajority","type":"int256"}],"name":"changeVotingRules","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"targetMember","type":"address"},{"name":"memberName","type":"string"}],"name":"addMember","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hammer","type":"address"}],"name":"setHammer","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"id","type":"uint256"},{"name":"supportsProposal","type":"bool"},{"name":"justificationText","type":"string"}],"name":"vote","outputs":[{"name":"vote","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"id","type":"uint256"},{"name":"beneficiary","type":"address"},{"name":"amount","type":"uint256"},{"name":"transactionBytecode","type":"bytes"}],"name":"checkProposalCode","outputs":[{"name":"codeChecksOut","type":"bool"}],"payable":false,"type":"function"},{"inputs":[{"name":"minimumQuorumForProposals","type":"uint256"},{"name":"minutesForDebate","type":"uint256"},{"name":"marginOfVotesForMajority","type":"int256"},{"name":"congressLeader","type":"address"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposal","type":"uint256"},{"indexed":true,"name":"recipient","type":"address"},{"indexed":true,"name":"amount","type":"uint256"},{"indexed":false,"name":"description","type":"string"}],"name":"ProposalAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposal","type":"uint256"},{"indexed":true,"name":"position","type":"bool"},{"indexed":true,"name":"voter","type":"address"},{"indexed":false,"name":"justification","type":"string"}],"name":"Voted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"proposal","type":"uint256"},{"indexed":true,"name":"quorum","type":"uint256"},{"indexed":true,"name":"active","type":"bool"}],"name":"ProposalTallied","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"member","type":"address"},{"indexed":true,"name":"isMember","type":"bool"}],"name":"MembershipChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"minimumQuorum","type":"uint256"},{"indexed":true,"name":"debatingPeriodInMinutes","type":"uint256"},{"indexed":true,"name":"majorityMargin","type":"int256"}],"name":"ChangeOfRules","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":true,"name":"amount","type":"uint256"}],"name":"ReceivedEther","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"value","type":"uint256"},{"indexed":true,"name":"token","type":"address"},{"indexed":false,"name":"extraData","type":"bytes"}],"name":"ReceivedTokens","type":"event"}]'; }
}

 
contract Builder is Object {
     
    event Builded(address indexed client, address indexed instance);
 
     
    mapping(address => address[]) public getContractsOf;
 
     
    function getLastContract() constant returns (address) {
        var sender_contracts = getContractsOf[msg.sender];
        return sender_contracts[sender_contracts.length - 1];
    }

     
    address public beneficiary;

     
    function setBeneficiary(address _beneficiary) onlyOwner
    { beneficiary = _beneficiary; }

     
    uint public buildingCostWei;

     
    function setCost(uint _buildingCostWei) onlyOwner
    { buildingCostWei = _buildingCostWei; }

     
    string public securityCheckURI;

     
    function setSecurityCheck(string _uri) onlyOwner
    { securityCheckURI = _uri; }
}

 
 
 
contract BuilderCongress is Builder {
     
    function create(uint256 minimumQuorumForProposals,
                    uint256 minutesForDebate,
                    int256 marginOfVotesForMajority,
                    address congressLeader,
                    address _client) payable returns (address) {
        if (buildingCostWei > 0 && beneficiary != 0) {
             
            if (msg.value < buildingCostWei) throw;
             
            if (!beneficiary.send(buildingCostWei)) throw;
             
            if (msg.value > buildingCostWei) {
                if (!msg.sender.send(msg.value - buildingCostWei)) throw;
            }
        } else {
             
            if (msg.value > 0) {
                if (!msg.sender.send(msg.value)) throw;
            }
        }

        if (_client == 0)
            _client = msg.sender;
 
        if (congressLeader == 0)
            congressLeader = _client;

        var inst = CreatorCongress.create(minimumQuorumForProposals,
                                          minutesForDebate,
                                          marginOfVotesForMajority,
                                          congressLeader);
        inst.setOwner(_client);
        inst.setHammer(_client);
        getContractsOf[_client].push(inst);
        Builded(_client, inst);
        return inst;
    }
}