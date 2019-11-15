#include "vntlib.h"

constructor Function5(){}

MUTABLE
uint32 test1(){
    uint32 res = test2();
    PrintUint256T("recurrent times:", res);
    return res;
}

MUTABLE
uint256 test2() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    uint64 aa = test3(a, i);

    return aa;
}

MUTABLE
uint64 test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    if (a >= i) {
        Revert("require a < i");
    }
    uint32 ai = test1();
    return ai;
}

