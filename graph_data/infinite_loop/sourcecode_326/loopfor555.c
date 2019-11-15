#include "vntlib.h"

 
KEY uint256 count;

constructor For5(){
}

MUTABLE
uint256 test1(){

    for (int32 k = -1; k = 1; k++) {
        count++;
    }

    return count;
}

uint256 test2() {
    return test1();
}
