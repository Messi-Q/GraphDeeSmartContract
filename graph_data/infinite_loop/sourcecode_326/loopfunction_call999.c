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
    uint256 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    test3(a, i);

    return i;
}

MUTABLE
uint256 test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
    return a;
}

