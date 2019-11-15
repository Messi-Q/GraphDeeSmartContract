#include "vntlib.h"

KEY uint16 count = 1000

constructor Fallback4() {}

MUTABLE
uint16 test1(uint16 amount){
    for(uint8 i = 0; i< amount; i++) {
        count += i;
    }

    return count;
}

 
_(){
   uint16 res = test1(count);
   PrintInt16T("res", res);
}