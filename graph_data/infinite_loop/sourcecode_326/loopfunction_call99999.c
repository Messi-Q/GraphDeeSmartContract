#include "vntlib.h"

constructor Function5(){}

MUTABLE
void test1(){
    uint16 res = test2();
    PrintUint16T("recurrent times:", res);
}

MUTABLE
uint16 test2() {
    uint16 a = 20;
    uint16 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    test3(a, i);

    return i;
}

MUTABLE
void test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
}

