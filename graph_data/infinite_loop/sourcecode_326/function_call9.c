#include "vntlib.h"

constructor Function5(){
    PrintStr("recurrent times:", "recurrent times");
}

MUTABLE
uint256 test1() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    test2(a, i);

    return i;
}

MUTABLE
void test2(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    PrintUint256T("a < i", a);
}

MUTABLE
void test3(uint256 a, uint256 i) {
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
}