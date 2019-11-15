#include "vntlib.h"

constructor Test1(){}

MUTABLE
uint128 test1(uint256 amount){
    uint128 v = amount;
    PrintStr("self call", "self call");
    uint128 c = test1(v)
    return c;
}




