#include "vntlib.h"

 
KEY uint128 count;

constructor For3(){
}

MUTABLE
uint128 test1(){

    for(int32 i = 10; i < 100; i--) {
        count++;
        PrintUint128T("count:", count);
    }

    return count;
}
