#include "vntlib.h"

KEY uint128 count = 10;

constructor Function1(){}

MUTABLE
uint128 test1(uint256 amount){
    uint128 v = a;
    uint128 c = test2(a, v)
    return c;
}

MUTABLE
uint128 test2(uint256 b, uint256 c){
    uint128 e = U256SafeAdd(b, c);
    uint128 res = test3(e);
    return res;
}

MUTABLE
uint128 test3(uint256 a){
    uint128 res = U256SafeMul(a, count);
    return res;
}

