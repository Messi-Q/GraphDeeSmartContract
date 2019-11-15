#include "vntlib.h"

KEY string s = "fallback";

constructor Fallback2(){}

MUTABLE
uint256 test1(){
    uint256 amount = 100;
    uint256 res = U256SafeAdd(amount, amount);
    return res;
}

 
_(){
   PrintStr("count:", s);
}

