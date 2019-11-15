#include "vntlib.h"

KEY uint8 count = 10;

constructor Fallback1() {}

 
 
CALL uint16 test(CallParams params, uint8 amount);
CallParams params = {Address("0xaaaa"), U256(10000), 100000};   

MUTABLE
uint64 test2(uint256 amount){
    test1(amount)
    uint32 res = amount + 1;
    return res;
}

MUTABLE
uint64 test1(uint256 amount){
    PrintStr("fallback", "fallback")
    uint256 res = test(param, amount)
    return res;
}

 
_(){
   test2(count);
}