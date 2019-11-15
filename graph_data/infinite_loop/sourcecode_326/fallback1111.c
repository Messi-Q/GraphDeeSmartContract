#include "vntlib.h"

KEY uint8 count = 10;

constructor Fallback1(){

}

 
 
CALL uint128 test(CallParams params, uint32 amount);
CallParams params = {Address("0xaaaa"), U256(10000), 100000};   


MUTABLE
uint128 test1(uint8 amount){
    test(param, amount)
    return amount;
}

MUTABLE
uint128 test2(uint8 amount){
    test1(amount)
    uint128 res = amount + 1;
    return res;
}

 
_(){
   string s = "Input data error";
   PrintStr("ERROR:", s);
}