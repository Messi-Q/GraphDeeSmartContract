#include "vntlib.h"

KEY uint256 count = 0;

constructor While1(){}

MUTABLE
uint256 test(uint256 x){
    PrintStr("test()", "test()")

    while(1 == 1) {
        count = x;
    }

    while(true) {
        count = x;
    }

    return count;
}
