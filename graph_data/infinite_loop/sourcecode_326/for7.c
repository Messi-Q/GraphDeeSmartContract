#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For7(){
}

MUTABLE
uint32 test1(){
    for (uint32 i = 1000; i > 0; i-=2) {
        count++;
    }

    return count;
}
