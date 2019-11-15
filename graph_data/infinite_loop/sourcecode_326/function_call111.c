#include "vntlib.h"

KEY uint64 count = 10;

constructor Function1(){}

MUTABLE
uint64 test1(uint256 a){
    uint64 v = a;
    uint64 c = test2(a, v)
    return c;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint64 e = U256SafeAdd(b, c);
    uint64 res = test3(e);
    return res;
}

MUTABLE
uint64 test3(uint256 a){
    uint64 res = U256SafeMul(a, count);
    return res;
}

