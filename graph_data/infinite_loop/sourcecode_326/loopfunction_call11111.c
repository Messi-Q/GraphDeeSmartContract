#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint16 test1(uint256 amount){
    uint16 v = amount;
    uint16 c = test2(amount, v);
    return c;
}

MUTABLE
uint16 test2(uint256 b, uint256 c){
    uint16 e = U256SafeAdd(b, c);
    uint16 res = test3(e);
    return res;
}

MUTABLE
uint16 test3(uint16 a){
    uint16 res = test1(a);
    return res;
}

$_() {}
