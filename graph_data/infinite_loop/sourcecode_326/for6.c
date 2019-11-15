#include "vntlib.h"

 
KEY uint256 count;

constructor For6(){
}

MUTABLE
uint32 test1(){
    for (uint8 i =0; i < 254; i++) {
        count++;
    }

    return count;
}
