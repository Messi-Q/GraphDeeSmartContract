#include "vntlib.h"

 
KEY uint128 count;

constructor For6(){
}

MUTABLE
uint128 test1(){
    for (; ;) {
        count++;
    }

    return count;
}
