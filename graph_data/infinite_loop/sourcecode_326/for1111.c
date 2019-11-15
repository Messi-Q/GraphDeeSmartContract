#include "vntlib.h"

 
KEY uint128 count;

constructor For1(){
}

 
 
 
 
MUTABLE
uint128 test1(){
    for (uint8 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
