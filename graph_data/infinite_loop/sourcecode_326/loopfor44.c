#include "vntlib.h"

 
KEY uint64 count = 1;

constructor For4(){}

MUTABLE
uint32 test1() {

    uint32 res = test2();

    while(res > 0) {
        res--;
        count += res;
    }

    return count;
}

MUTABLE
uint64 test2() {

    for(uint16 i = 0; i < 1000000000; i++) {
        count++;
        PrintStr("uint16:", "uint16 < 1000000000");
    }

    return count;
}

_() {
    test1();
}