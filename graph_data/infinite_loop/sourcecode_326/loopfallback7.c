#include "vntlib.h"

KEY uint256 amount = 100;

typedef struct fallback7 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback7() {}

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

 
_(){
   while(true){
    test1();
   }
}