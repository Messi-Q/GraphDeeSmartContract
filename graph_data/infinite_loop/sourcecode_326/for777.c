#include "vntlib.h"

 
KEY uint256 count;

constructor For7(){
}

MUTABLE
uint256 test1(){
    PrintStr("count", "count");
    for (uint32 i = 1000; i > 0; i-=2) {
        count++;
    }

    return count;
}
