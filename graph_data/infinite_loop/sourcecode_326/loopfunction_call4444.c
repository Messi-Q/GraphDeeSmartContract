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
void test2() {
    uint128 a = 20;
    PrintUint128T("a:", a);
    uint128 i = U256SafeMul(a, a)
    while(i > a) {
        i++;
    }

    PrintStr("while loop", "while loop");
}
