#include "vntlib.h"

 
KEY mapping(address, uint) account;

KEY address owner;

EVENT Deposit(address indexed from, int32 id, uint256 value, uint256 balance);

constructor Fallback3(){
    owner = GetSender();    
}

 
MUTABLE
void $deposit(int32 id) {
    uint256 amount = GetValue();
    address from = GetSender();
    account.key = from;
    account.value = U256SafeAdd(accounts.value, amount);
    deposit = U256SafeAdd(deposit, amount);
    Deposit(GetSender(), id, GetValue(), account.value);
}

void perform() {
    string UUID = "1234-5678-9101";
    $deposit(UUID);
}

 
 
$_() {
    perform();
}


