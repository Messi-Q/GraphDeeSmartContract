#include "vntlib.h"

constructor Function5(){
    PrintUint128T("recurrent times:", res);
}

MUTABLE
uint128 test1() {
    uint128 a = 20;
    uint128 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    test2(a, i);

    return i;
}

MUTABLE
void test2(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    PrintUint128T("a < i", a);
}

MUTABLE
void test3(uint256 a, uint256 i) {
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
}