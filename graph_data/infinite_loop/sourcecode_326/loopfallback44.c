#include "vntlib.h"

KEY uint256 count = 1000;

constructor Fallback4() {}

MUTABLE
void test1(uint256 count){
    PrintStr("For and Fallback", "For and Fallback")

    for(uint8 i = 0; i< count; i++) {
        count += i;
    }
}

 
_(){
   test1(count);
}