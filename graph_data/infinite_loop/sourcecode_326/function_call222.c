#include "vntlib.h"

KEY uint256 count = 10;

constructor Function2(){}

MUTABLE
uint256 test1(uint256 a){
    PrintStr("v = a", "v = a");
    uint256 v = a;
    uint256 c = test2(a, v);
    return c;
}

MUTABLE
uint256 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint256 res = U256SafeSub(e, count);
    return res;
}


