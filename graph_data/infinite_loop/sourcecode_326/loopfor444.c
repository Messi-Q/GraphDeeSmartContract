#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For4(){
}

MUTABLE
uint256 test1() {
    for(uint16 i = 0; i < 1000000000; i++) {
        count++;
        PrintStr("uint16:", "uint16 < 1000000000");
    }

    return count;
}

MUTABLE
uint256 test2() {
    PrintStr("test3()", "test3()");
    return test3();
}

MUTABLE
uint256 test3() {
    uint32 res = test1();

    while(res != 0) {
        res--;
        count += res;
    }

    return count;
}

_() {
    test3();
}