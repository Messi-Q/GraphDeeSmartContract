#include "vntlib.h"

KEY uint256 count = U256(1000000000);

constructor Fallback1() {

}
 
 
CALL uint32 test(CallParams params, uint32 amount);
CallParams params = {Address("0xaaaa"), U256(10000), 100000};   

MUTABLE
uint256 test1(uint8 amount){
    PrintStr("fallback", "fallback")
    test(param, amount)
    return amount;
}

MUTABLE
uint256 test2(uint8 amount){
    test1(amount)
    uint256 res = amount + 1;
    return res;
}

 
_(){
   test2(count);
}