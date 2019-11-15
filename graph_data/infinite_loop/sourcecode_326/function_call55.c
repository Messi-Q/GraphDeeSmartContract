#include "vntlib.h"

constructor Function5(){}

MUTABLE
uint64 test1(){
    uint64 res = test2();
    PrintUint256T("recurrent times:", res);
    return res;
}

MUTABLE
uint64 test2() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint64 i = U256SafeMul(a, a)

    while(i > a) {
        Require(i > a, "i > a");
        test3(a, i);
        i--;
    }

    return i;
}

MUTABLE
string test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    return "a < i";
}

