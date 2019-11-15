#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For5(){
}

MUTABLE
uint32 test1(){

    for (int32 k = -1; k = 1; k++) {
        count++;
    }

    return count;
}

void test2() {
    test1();
}
