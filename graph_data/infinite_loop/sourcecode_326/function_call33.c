#include "vntlib.h"

KEY uint256 v;

KEY mapping(address, uint) account;

constructor Test1(){}

MUTABLE
uint64 test1(uint256 amount){
    v = amount;
    vv = test1(amount);
    address to = GetSender();
    account.key = to;
    account.value = U256SafeAdd(vv, v);
    return account.value;
}

UNMUTABLE
uint256 test1(uint256 amount){
    if (amount > 50) {
        return amount;
    } else {
        return U256SafeAdd(amount, amount);
    }
}

