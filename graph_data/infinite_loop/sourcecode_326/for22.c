#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For2(){}

 
 
 
 
MUTABLE
uint64 test1(){
    for (uint32 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }
    return count;
}

 
UNMUTABLE
uint64 GetCount() {
    PrintStr("uint256:", "count < 1000");
    return test1();
}