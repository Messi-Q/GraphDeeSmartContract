#include "vntlib.h"

 
KEY uint256 count;

constructor For1(){}

 
 
 
 
MUTABLE
uint256 test1(){
    PrintStr("This is a example", "This is a example");

    for (uint8 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
