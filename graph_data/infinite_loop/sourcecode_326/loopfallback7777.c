#include "vntlib.h"

KEY uint128 amount = 100;

typedef struct fallback7 {
    uint128 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback7() {}

MUTABLE
void test1(){
    PrintStr("getRes", "getRes");
    getRes(GetSender(), amount);
}

uint128 getRes(address addr, uint128 amount) {
    accounts.key = addr;
    uint128 balance = accounts.value.balance;
    uint128 res = U256SafeAdd(balance, amount);

    return res;
}

 
_(){
   while(true){
      test1();
   }
}