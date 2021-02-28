#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint64 test1(uint64 amount){
    uint64 v = amount;
    uint64 c = test1(amount);
    return c;
}


MUTABLE
uint64 test3(uint256 a){
    uint64 res = test1(a);
    return res;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint64 e = U256SafeAdd(b, c);
    uint64 res = test3(e);
    return res;
}


