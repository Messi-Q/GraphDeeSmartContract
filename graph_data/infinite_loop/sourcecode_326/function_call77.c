#include "vntlib.h"

constructor Function7(){}

MUTABLE
uint64 test1(uint256 amount){
    uint256 v = U256SafeMul(a, a);
    uint64 c = test2(a, v)
    return c;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint256 res = test3(e);
    return res;
}


MUTABLE
uint32 test3(uint256 a){
    uint32 minutes = 0;
    do {
        PrintStr("How long is your shower(in minutes)?:", "do...while");
        minutes += 1;
    } while (minutes < 1);

    return minutes;
}

