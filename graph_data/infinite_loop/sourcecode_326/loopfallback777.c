#include "vntlib.h"

KEY uint64 amount = 100;

typedef struct fallback7 {
    uint256 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback7() {}

MUTABLE
void test1(){
    PrintStr("getRes", "getRes");
    getRes(GetSender(), amount);
}

uint64 getRes(address addr, uint32 amount) {
    accounts.key = addr;
    uint256 balance = accounts.value.balance;
    uint64 res = U256SafeAdd(balance, amount);

    return res;
}

 
_(){
   while(true){
      test1();
   }
}