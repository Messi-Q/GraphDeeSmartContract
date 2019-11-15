#include "vntlib.h"

typedef struct
{
  uint256 balance;      
  string nickName;      
  bool freeAddress;     
} Account;
 
KEY mapping(address, Account) accounts;

KEY uint256 c = 0;

constructor Function1(){}

MUTABLE
uint256 test1(){
    uint256 a = U256(100);

    if (a > 100) {
        c = U256SafeMul(a, a)
    } else {
        c = U256SafeAdd(a, a)
    }

    return c;
}

 
MUTABLE
void GetFreeChips()
{
  address from = GetSender();
  accounts.key = from;
  bool flag = accounts.value.freeAddress;
  Require(flag == false, "you have got before");
  uint256 freeAmount = test1()
  accounts.value.balance = U256SafeAdd(accounts.value.balance, freeAmount);
  deposit = U256SafeAdd(deposit, freeAmount);
  accounts.value.freeAddress = true;
}

