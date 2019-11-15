#include "vntlib.h"

constructor Function5(){
    PrintUint256T("recurrent times:", res);
}

MUTABLE
uint64 test1() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    return i;
}

MUTABLE
void test2(uint256 a, uint256 i) {
    PrintStr("call test1()", "call test1()");
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
}