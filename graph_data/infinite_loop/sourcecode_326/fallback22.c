#include "vntlib.h"

KEY string s = "Fallback";

constructor Fallback2(){}

MUTABLE
uint64 test1(){
    PrintStr("Fallback", "Fallback")
    uint32 amount = 100;
    uint32 res = U256SafeAdd(amount, amount);
    return res;
}

 
_(){
   PrintStr("count:", s);
}

