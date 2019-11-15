#include "vntlib.h"

KEY uint128 count = 0;
KEY string ss = "qian";

constructor While3(){
}

 
MUTABLE
uint128 test1(string s){
    isDone = Equal(s, ss);
    uint128 res = test2(isDone)
    return res;
}

MUTABLE
uint128 test2(bool isDone){
     while(count < 3) {
        if(isDone) {
            continue;
        }
        count++;
     }
     return count;
}
