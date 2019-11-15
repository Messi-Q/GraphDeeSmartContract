#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For3(){
}

MUTABLE
uint16 test1(){
    for(int32 i = 10; i < 100; i++) {
        count++;
        PrintUint16T("count:", count);
    }

    return count;
}
