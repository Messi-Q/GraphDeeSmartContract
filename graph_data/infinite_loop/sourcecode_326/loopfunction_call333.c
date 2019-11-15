#include "vntlib.h"

KEY uint256 v;

constructor Test1(){}

MUTABLE
uint256 test1(uint256 amount){
    uint256 v = amount;
    PrintStr("v = amount", "v = amount")
    uint256 c = test1(v)
    return c;
}




