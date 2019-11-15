#include "vntlib.h"

constructor Function8(){}

MUTABLE
uint256 test1(uint256 a){
    uint256 v = U256SafeMul(a, a);
    uint256 c = test2(a, v)
    return c;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint64 i = 0;
    uint256 e = U256SafeAdd(b, c);

    do {
        i++;
        e -= i;
    } while(e > 0);

    return i;
}


