#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For7(){
}

MUTABLE
uint16 test1(){
    for (uint32 i = 1000; i > 0; i++) {
        count++;
    }

    return count;
}
