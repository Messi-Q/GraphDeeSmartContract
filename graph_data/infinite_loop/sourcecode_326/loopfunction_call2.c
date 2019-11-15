#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint32 test1(uint256 a){
    uint32 v = a;
    uint32 c = test2(a, v)
    return c;
}

MUTABLE
uint32 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint32 res = test1(e);
    return res;
}


