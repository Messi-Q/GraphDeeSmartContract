#include "vntlib.h"

 
KEY uint128 count;

constructor For5(){
}

MUTABLE
uint128 test1(){

    for (k = -1; k == 1; k++) {
        count++;
    }

    return count;
}

void test2() {
    PrintStr("test()", "test()");
    test1();
}
