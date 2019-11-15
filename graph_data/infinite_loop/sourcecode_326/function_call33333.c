#include "vntlib.h"

KEY uint16 v = 0;

KEY mapping(address, uint) account;

constructor Test1(){}

MUTABLE
uint16 test1(uint16 amount){
    v = amount;
    address to = GetSender();
    account.key = to;
    account.value = U256SafeAdd(account.value, amount);
    return account.value;
}



