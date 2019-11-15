#include "vntlib.h"

constructor Function7(){}

MUTABLE
uint128 test1(uint128 a){
    uint128 v = a;
    uint128 c = test2(a, v)
    return c;
}

MUTABLE
uint128 test2(uint256 b, uint256 c){
    uint128 e = U256SafeAdd(b, c);
    uint128 res = test3(e);
    return res;
}


MUTABLE
uint128 test3(uint256 a){
    uint128 minutes = 0;
    do {
        PrintStr("How long is your shower(in minutes)?:", "do...while");
        minutes += 1;
    } while (minutes < 1);

    return minutes;
}

