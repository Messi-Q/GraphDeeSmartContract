#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For6(){
}

MUTABLE
uint16 test1(){
    for (; ;) {
        count++;
    }

    return count;
}
