#include "vntlib.h"

KEY uint256 count = 10;

constructor Function1(){}


MUTABLE
uint256 test3(uint256 a){
    uint256 res = U256SafeMul(a, count);
    return res;
}

MUTABLE
uint256 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint32 res = test3(e);
    return res;
}

MUTABLE
uint256 test1(uint256 a){
    uint256 v = a;
    uint256 c = test2(a, v);
    return c;
}

