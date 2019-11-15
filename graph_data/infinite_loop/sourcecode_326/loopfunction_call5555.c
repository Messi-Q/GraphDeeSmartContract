#include "vntlib.h"

constructor Function5(){}

MUTABLE
uint128 test1(){
    uint128 res = test2();
    PrintUint128T("recurrent times:", res);
    return res;
}

MUTABLE
uint128 test2() {
    uint128 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a)

    while(i > a) {
        Require(i > a, "i > a");
        i++;
    }

    return i;
}

