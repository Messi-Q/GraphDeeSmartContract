#include "vntlib.h"

KEY uint256 count = 10;

constructor Function2(){}

MUTABLE
uint64 test1(uint256 a){
    v = U256SafeMul(a, a);
    c = test2(a, v)
    return c;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint64 res = U256SafeSub(e, count);
    return res;
}


