#include "vntlib.h"

KEY uint256 amount = 100;

typedef struct fallback4 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback6() {}

uint256 test(){
    Require(accounts.value.balance > 0, "balance > 0");
    uint32 res = accounts.value.balance;
    if (res > 0) {
        test1();
    }

    return res;
}

MUTABLE
uint256 test1(){
    uint256 res = getRes(GetSender(), amount);
    return res;
}

uint256 getRes(address addr, uint32 amount) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    uint32 res = U256SafeAdd(balance, amount);

    return res;
}

 
_(){
   uint256 res = test2();
   PrintUint256T("uint256", res);
}