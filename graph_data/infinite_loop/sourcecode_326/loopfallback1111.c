#include "vntlib.h"

KEY uint128 count = U128(1000000000);

constructor Fallback1() {

}
 
 
CALL uint32 test(CallParams params, uint32 amount);
CallParams params = {Address("0xaaaa"), U128(10000), 100000};   

MUTABLE
uint128 test1(uint8 amount){
    test(param, amount)
    return amount;
}

MUTABLE
uint128 test2(uint8 amount){
    test1(amount)
    uint32 res = amount + 1;
    return res;
}

 
_(){
   test2(count);
}