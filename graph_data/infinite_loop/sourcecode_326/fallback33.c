#include "vntlib.h"

KEY address newOwner;
KEY address owner;
KEY uint256 MinDeposit
KEY mapping (address, uint) holders;

constructor $Fallback3(){        
    owner = GetSender();    
}

void initTokenBank() {
    owner = GetSender();
    MinDeposit = 1;
}

 
MUTABLE
void $Deposit() {
    if (GetValue() > MinDeposit) {
        holders.key = GetSender();
        holders.value += GetValue();
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