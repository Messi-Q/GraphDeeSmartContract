#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For2(){
}

 
 
 
 
MUTABLE
uint16 test1(){
    for (uint32 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }
    return count;
}

 
UNMUTABLE
uint16 GetCount() {
    return test1();
}