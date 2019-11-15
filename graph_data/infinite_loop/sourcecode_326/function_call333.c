#include "vntlib.h"

KEY uint256 v;

KEY mapping(address, uint) account;

constructor Test1(){}

MUTABLE
uint256 test1(uint256 amount){
    uint256 v = amount;
    address to = GetSender();
    account.key = to;
    account.value = U256SafeAdd(account.value, amount);
    return account.value;
}

_() {}


