#include "vntlib.h"

constructor Function5(){}

MUTABLE
uint256 test1(){
    uint256 res = test2();
    PrintUint256T("recurrent times:", res);
    return res;
}

MUTABLE
uint256 test2() {
    uint256 a = 20;
    uint256 i = U256SafeMul(a, a)

    while(i > a) {
        Require(i > a, "i > a");
        test3(a, i);
        i++;
    }

    return i;
}

MUTABLE
uint256 test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    return a;
}

