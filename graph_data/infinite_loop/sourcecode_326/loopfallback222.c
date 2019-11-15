#include "vntlib.h"

KEY string s = "fallback";

constructor Fallback2(){}

MUTABLE
uint256 test1(uint32 amount){
    uint256 res = U256SafeAdd(amount, amount);
    return res;
}

 
_(){
   uint256 res = test1(s);
   PrintUint256T("res", res)
}

