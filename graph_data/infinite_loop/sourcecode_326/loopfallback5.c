#include "vntlib.h"

KEY uint256 res = 100;

typedef struct fallback4 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5() {}

MUTABLE
void test1(){
    uint256 res = getRes(GetSender());
    PrintUint256T("uint256", res);
}

uint256 getRes(address addr) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    while(balance >= 0) {
        res += balance;
    }

    return res;
}

 
_(){
   test1();
}