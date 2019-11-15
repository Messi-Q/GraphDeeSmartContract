#include "vntlib.h"


constructor Test1(){}

MUTABLE
uint64 test1(uint256 amount){
    uint64 v = U256SafeMul(amount, amount);
    uint64 c = test1(v)
    return c;
}




