#include "vntlib.h"

KEY string s = "fallback";

constructor Fallback2(){}

MUTABLE
uint128 test1(){
    uint128 amount = 100;
    uint128 res = U256SafeAdd(amount, amount);
    return res;
}

 
_(){
   PrintStr("count:", s);
}

