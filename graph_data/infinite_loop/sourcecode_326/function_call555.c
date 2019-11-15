#include "vntlib.h"

constructor Function5(){}

MUTABLE
uint32 test1(){
    uint32 res = test2();
    PrintUint256T("recurrent times:", res);
    return res;
}

MUTABLE
uint64 test2() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a)

    while(i > a) {
        Require(i > a, "i > a");
        i--;
    }

    return i;
}


