#include "vntlib.h"

KEY uint128 res = 100;

typedef struct fallback4 {
    uint128 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5() {}

uint128 getRes(address addr) {
    accounts.key = addr;

    uint128 balance = accounts.value.balance;
    while(balance >= 0) {
        res += balance;
    }

    return res;
}

 
_(){
   getRes(GetSender());
}