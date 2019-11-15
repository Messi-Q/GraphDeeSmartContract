#include "vntlib.h"

KEY uint128 count = 10;

constructor Function2(){}

MUTABLE
uint128 test1(uint128 a){
    uint128 v = a;
    uint128 c = test2(a, v)
    return c;
}

MUTABLE
uint128 test2(uint256 b, uint256 c){
    uint128 e = U256SafeAdd(b, c);
    uint128 res = U256SafeSub(e, count);
    return res;
}


