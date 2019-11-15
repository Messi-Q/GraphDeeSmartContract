#include "vntlib.h"

constructor Function7(){}

MUTABLE
uint256 test1(uint256 a){
    v = a;
    c = test2(a, v)
    return c;
}

MUTABLE
uint256 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint256 res = test3(e);
    return res;
}


MUTABLE
uint256 test3(uint256 a){
    uint256 minutes = 0;
    do {
        PrintStr("How long is your shower(in minutes)?:", "do...while");
        minutes += 1;
    } while (minutes < 1);

    PrintUint256T("minutes", minutes);

    return minutes;
}

