#include "vntlib.h"

KEY string s = "fallback";

constructor Fallback2(){}

MUTABLE
uint32 test1(uint32 amount){
    uint32 res = U256SafeAdd(amount, amount);
    return res;
}

 
_(){
   test1(s);
}

