#include "vntlib.h"

KEY uint128 res = 100;

typedef struct fallback4 {
    uint128 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5{}

uint128 getRes(address addr) {
    accounts.key = addr;

    uint128 balance = accounts.value.balance;
    Require(balance > 0, "balance > 0");

    while(balance > 0) {
        res += balance;
    }

    return res;
}

MUTABLE
void test1(){
    uint128 res = getRes(GetSender());
    PrintUint128T("uint256", res);
}


 
_(){
   test1();
}