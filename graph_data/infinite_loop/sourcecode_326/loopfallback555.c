#include "vntlib.h"

KEY uint256 res = 100;

typedef struct fallback4 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5() {}

uint256 getRes(address addr) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    while(balance >= 0) {
        res += balance;
    }

    return res;
}

 
_(){
   getRes(GetSender());
}