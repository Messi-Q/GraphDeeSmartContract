#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint16 test1(uint256 a){
    uint16 v = a;
    uint16 c = test2(a, v)
    return c;
}

MUTABLE
uint16 test2(uint256 b, uint256 c){
    uint16 e = U256SafeAdd(b, c);
    uint16 res = test1(e);
    return res;
}


