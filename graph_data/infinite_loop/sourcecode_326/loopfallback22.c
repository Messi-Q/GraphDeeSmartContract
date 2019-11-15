#include "vntlib.h"

KEY string s = "Fallback recurrent";

constructor Fallback2(){}

MUTABLE
uint64 test1(uint32 amount){
    PrintStr("Fallback", "Fallback")
    uint64 res = U256SafeAdd(amount, amount);
    return res;
}

_(){
   test1(s);
}

