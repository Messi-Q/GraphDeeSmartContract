#include "vntlib.h"

KEY uint256 count = U256(1000000000);

constructor Fallback1() {

}
 
CALL uint32 test(CallParams params, uint32 amount);
CallParams params = {Address("0xaaaa"), U256(10000), 100000};   

MUTABLE
uint32 test1(uint32 amount){
    test(params, amount);
    return amount;
}

MUTABLE
uint32 test2(uint32 amount){
    test1(amount);
    uint32 res = amount + 1;
    return res;
}

 
_(){
   test2(count);
}