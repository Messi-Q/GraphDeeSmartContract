#include "vntlib.h"

constructor Test1(){}

 
CALL uint128 test2(CallParams params);
CallParams params = {Address("0xaaaa"), U256(10000), 100000};   


MUTABLE
uint128 test1(){
    uint128 res = test2(params);
    PrintUint128T("res:", res);
    return res;
}

#include "vntlib.h"

 
constructor Test2(){}

MUTABLE
bool test2() {
    uint128 a = 20;
    uint128 i = U256SafeMul(a, a)
    while(i > a) {
        a++;
    }

    return true;
}
