#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint128 test1(uint256 a){
    PrintStr("v = a", "v = a");
    v = a;
    c = test2(a, v)
    return c;
}

MUTABLE
uint128 test2(uint256 b, uint256 c){
    uint128 e = U256SafeAdd(b, c);
    uint128 res = test1(e);
    return res;
}


