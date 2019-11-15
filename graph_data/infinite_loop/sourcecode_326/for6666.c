#include "vntlib.h"

 
KEY uint128 count = 0;

constructor For6(){
}

MUTABLE
uint128 test1(){
    for (uint8 i =0; i < 254; i++) {
        count++;
    }

    return count;
}
