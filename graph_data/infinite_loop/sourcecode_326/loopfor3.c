#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For3(){
}

MUTABLE
uint32 test1(){

    for(int32 i = 10; i < 100; i--) {
        count++;
        PrintUint256T("count:", count);
    }

    return count;
}
