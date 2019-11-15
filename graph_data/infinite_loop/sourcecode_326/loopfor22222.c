#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For2(){
}

MUTABLE
uint16 test1(){
    uint16 x = 0;
    for (uint32 i = 0; i < 2000; i++) {
        for(uint8 j = 0; j < 1000; j++){
            count += 2;
            if(count > 50) {
                x = count;
            }
        }
    }
    return x;
}

 
UNMUTABLE
uint16 GetCount() {
    return test1();
}