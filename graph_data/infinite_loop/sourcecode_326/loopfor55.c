#include "vntlib.h"

 
KEY uint256 count;

constructor For5(){}

void test1() {
    PrintStr("Test()", "Call Test")
    test1();
}

MUTABLE
uint64 test2(){

    for (int32 k = -1; k = 1; k++) {
        count++;
    }

    return count;
}
