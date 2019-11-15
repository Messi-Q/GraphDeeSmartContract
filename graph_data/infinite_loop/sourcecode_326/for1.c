#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For1(){
}

 
 
 
 
MUTABLE
uint32 test1(){
    for (uint8 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
