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

 
void delegate(address to) {
    sender = GetSender();

    while(voters[to].delegate != sender){
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
