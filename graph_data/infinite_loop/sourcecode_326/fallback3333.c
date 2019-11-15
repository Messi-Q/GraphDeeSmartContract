#include "vntlib.h"

KEY address newOwner;

KEY address owner;

KEY uint128 MinDeposit;

KEY mapping (address, uint) holders;

constructor $Fallback3(){        
    owner = GetSender();    
}

uint128 initTokenBank() {
    owner = GetSender();
    MinDeposit = 1;
    return MinDeposit;
}

 
MUTABLE
void $Deposit() {
    if (GetValue() > MinDeposit) {
        holders.key = GetSender();
        holders.value += GetValue();
    }
}

void WithdrawTokenToHolder(address _to, uint _amount) {
    holders.key = to
    if(holders.value > 0) {
        holders.value = 0;
        SendFromContract(to, amount);
    }
}

void WithdrawToHolder(address _addr, uint _amount) {
    holders.key = addr
    if(holders.value > 0) {
        if(TransferFromContract(_addr, _amount) == true){
            Holders.value -= _amount;
        }
    }
}

$_() {
    $Deposit();
}