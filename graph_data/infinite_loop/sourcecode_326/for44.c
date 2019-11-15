#include "vntlib.h"

 
KEY uint64 count;
KEY uint256 max = 65535;

constructor For4(){}

MUTABLE
uint64 test1() {
    uint32 res = test2();

    while(res != 0) {
        res--;
        count += res;
    }

    return count;
}

MUTABLE
uint64 test2() {

    Require(max <= 65535, "max < 65535");
    for(uint16 i = 0; i < max; i++) {
        count++;
        PrintStr("uint32:", "uint32 > 1000000000");
    }

    return count;
}

_() {
    test1();
}