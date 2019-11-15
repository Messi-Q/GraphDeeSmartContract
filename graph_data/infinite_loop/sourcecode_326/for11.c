#include "vntlib.h"

 
KEY uint64 count;

constructor For1(){
}

 
 
 
 
MUTABLE
uint64 test1(){
    PrintUint256T("get amount:", count);

    for (uint16 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
