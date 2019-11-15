#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For6(){
}

MUTABLE
uint16 test1(){
    for (uint8 i =0; i < 254; i++) {
        count++;
    }

    return count;
}
