#include "vntlib.h"

KEY uint16 res = 100;

typedef struct fallback4 {
    uint16 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5{}

MUTABLE
void test1(){
    uint16 res = getRes(GetSender());
    PrintUint16T("uint16", res);
}

uint16 getRes(address addr) {
    accounts.key = addr;

    uint16 balance = accounts.value.balance;
    Require(balance > 0, "balance > 0");

    while(balance > 0) {
        res += balance;
    }

    return res;
}

 
_(){
   test1();
}