#include "vntlib.h"

 
KEY uint128 count = 0;

constructor For2(){
}

 
 
 
 
MUTABLE
uint128 test1(){
    for (uint32 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }
    return count;
}

 
UNMUTABLE
uint128 GetCount() {
    return test1();
}