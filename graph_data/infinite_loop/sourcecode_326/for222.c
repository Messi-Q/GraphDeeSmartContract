#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For2(){}

 
 
 
 
MUTABLE
uint256 test1(){
    PrintStr("This is a example", "This is a example");
    for (uint32 i = 0; i < 2000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }
    return count;
}

 
UNMUTABLE
uint256 GetCount() {
    uint256 res = test1();
    PrintUint256T("res", res);
    return res;
}