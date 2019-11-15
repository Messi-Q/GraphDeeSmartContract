#include "vntlib.h"

constructor Function8(){}

MUTABLE
uint128 test1(uint256 a){
    uint128 v = a;
    uint128 c = test2(a, v)
    return c;
}

MUTABLE
uint128 test2(uint256 b, uint256 c){
    uint128 i = 0;
    uint128 e = U256SafeAdd(b, c);
    do {
        i++;
        e += i;
    } while(e > 0);

    return i;
}


