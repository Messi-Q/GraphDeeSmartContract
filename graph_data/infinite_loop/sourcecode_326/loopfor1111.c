#include "vntlib.h"

 
KEY uint128 count = 0;

constructor For1(){}

MUTABLE
uint128 test1(){
    PrintStr("uint128", "uint128")

    for (uint8 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
