#include "vntlib.h"

KEY uint256 count = 0;
KEY string ss = "qian";

constructor While3(){
}

 
MUTABLE
uint32 test1(string s){
    isDone = Equal(s, ss);
    uint32 res = test2(isDone)
    return res;
}

MUTABLE
uint32 test2(bool isDone){
     while(count < 3) {
        if(isDone) {
            continue;
        }
        count++;
     }
     return count;
}
