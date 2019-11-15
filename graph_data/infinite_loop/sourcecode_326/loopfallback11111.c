#include "vntlib.h"

KEY uint16 count = U256(1000000000);

constructor Fallback1() {

}
 
 
CALL uint16 test(CallParams params, uint32 amount);
CallParams params = {Address("0xaaaa"), U256(10000), 100000};   

MUTABLE
uint16 test1(uint8 amount){
    test(param, amount)
    return amount;
}

MUTABLE
uint16 test2(uint8 amount){
    test1(amount)
    uint16 res = amount + 1;
    return res;
}

 
_(){
   test2(count);
}