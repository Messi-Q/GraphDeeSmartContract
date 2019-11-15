#include "vntlib.h"

KEY uint16 amount = 100;

typedef struct fallback4 {
    uint16 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback6() {}

MUTABLE
void test1(){
    getRes(GetSender(), amount);
}

uint16 getRes(address addr, uint16 amount) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    uint32 res = U256SafeAdd(balance, amount);

    return res;
}

uint16 test2(){
    Require(accounts.value.balance > 0, "balance > 0");
    uint16 res = accounts.value.balance;
    if (res > 0) {
        test1();
    }

    return res;
}

 
_(){
   test2();
}