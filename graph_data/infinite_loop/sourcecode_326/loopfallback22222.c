#include "vntlib.h"

KEY string s = "fallback";

constructor Fallback2(){}

MUTABLE
uint16 test1(uint16 amount){
    uint16 res = U256SafeAdd(amount, amount);
    return res;
}

 
_(){
   test1(s);
}

