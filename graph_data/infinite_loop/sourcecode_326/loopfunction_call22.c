#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint64 test1(uint256 a){
    v = U256SafeMul(a, a);
    c = test2(a, v)
    return c;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint32 res = test1(e);
    return res;
}


