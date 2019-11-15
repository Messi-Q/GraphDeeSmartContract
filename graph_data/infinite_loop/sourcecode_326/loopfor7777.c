#include "vntlib.h"

 
KEY uint128 count = 0;

constructor For7(){
}

MUTABLE
uint128 test1(){
    for (uint32 i = 1000; i > 0; i++) {
        count++;
    }

    return count;
}
