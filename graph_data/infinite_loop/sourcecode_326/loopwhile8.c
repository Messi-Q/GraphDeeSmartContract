#include "vntlib.h"

typedef struct voter
{
    uint64 weight;      
    bool voted;     
    uint64 vote;      
    address delegate;   
} Voter;

KEY Voter sender;

typedef struct proposal
{
    string name; 
    uint64 voteCount; 
} Proposal;

 
KEY address chairperson;

 
KEY mapping(address, Voter) voters;

 
KEY array(Proposal) proposals;

 
constructor vote(array(string) proposalNames){
    chairperson = GetSender();
    voters.key = chairperson;
    voters.value.weight = 1;
    proposalNames.length = 32;

     
    for(uint64 i = 0; i < proposalNames.length; i++) {
         
        proposalNames.index = i;
        proposalNames.value = "proposalName" + FromU64(i);

        proposals.length = 100;
        proposals.index = i;
        proposals.value.name = proposalNames.value;
        proposals.value.voteCount = 0;
    }

}

 
void giveRightToVote(address voter) {
     
     
   require(GetSender() == chairperson, "Only chairperson can give right to vote.");
   require(!voters[voter].value.voted, "The voter already voted.");
   require(voters[voter].value.weight == 0);
   voters[voter].value.weight = 1;
}

 
void delegate(address to) {
     
    sender = GetSender();
    require(!sender.value.voted, "you already voted");
    require(to != GetSender(), "Self-delegation is disallowed.");

     
    while(voters[to].delegate){
        to = GetSender();
    }

     
    sender.value.voted = true;
    sender.value.delegate = to;
    delegate_ = voters[to];

    if(delegate_.value.voted){
         
        proposals[delegate_.value.vote].value.voteCount += sender.value.weight;
    }else{
         
        delegate_.value.weight += sender.value.weight;
     }
}
