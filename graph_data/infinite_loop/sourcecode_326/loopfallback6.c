#include "vntlib.h"

KEY uint256 amount = 100;

typedef struct fallback4 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback6() {}

MUTABLE
void test1(){
    getRes(GetSender(), amount);
}

uint256 getRes(address addr, uint32 amount) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    uint32 res = U256SafeAdd(balance, amount);

    return res;
}

uint256 test2(){
    Require(accounts.value.balance > 0, "balance > 0");
    uint32 res = accounts.value.balance;
    while (res > 0) {
        test1();
    }

    return res;
}

 
_(){
   test2();
}