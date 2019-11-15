#include "vntlib.h"

KEY uint16 amount = 100;

typedef struct fallback7 {
    uint16 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback7() {}

MUTABLE
void test1(){
    getRes(GetSender(), amount);
}

uint16 getRes(address addr, uint16 amount) {
    accounts.key = addr;

    uint16 balance = accounts.value.balance;
    uint16 res = U256SafeAdd(balance, amount);

    return res;
}

 
_(){
   while(true){
      test1();
   }
}