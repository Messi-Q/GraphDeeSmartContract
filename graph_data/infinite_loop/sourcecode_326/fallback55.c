#include "vntlib.h"

KEY uint256 res = 100;

typedef struct fallback4 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5{}

MUTABLE
uint256 test1(){
    uint256 res = getRes(GetSender());
    return res;
}

uint256 getRes(address addr) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    Require(balance > 0, "balance > 0");

    while(balance > 0) {
        res += balance;
    }

    return res;
}

 
_(){
   uint256 res = test1();
   PrintUint256T("uint256", res);
}